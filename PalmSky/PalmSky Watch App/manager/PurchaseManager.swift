import Foundation
import StoreKit

enum IAPPack: String, CaseIterable {
    case unlockGame = "com.palmsky.jindan"
    // 新增皮肤商品
    case skinFire = "com.palmsky.skin.fire"
}

// MARK: - Notification Names
extension Notification.Name {
    static let didPurchaseSuccess = Notification.Name("didPurchaseSuccess")
    static let didPurchaseFail = Notification.Name("didPurchaseFail")
    static let didRestorePurchases = Notification.Name("didRestorePurchases")
}

// MARK: - Purchase Error
enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case verificationFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return NSLocalizedString("找不到该商品", comment: "")
        case .purchaseFailed(let reason):
            return reason
        case .verificationFailed:
            return NSLocalizedString("购买验证失败", comment: "")
        case .userCancelled:
            return NSLocalizedString("购买取消", comment: "") //"User cancelled"
        }
    }
}

class PurchaseManager: NSObject, ObservableObject {
    
    static let shared = PurchaseManager()
    
    private let productIds: [String] = IAPPack.allCases.map { $0.rawValue }
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    // 本地缓存 key (支持离线使用)
    private let hasAccessCacheKey = SkyConstants.UserDefaults.hasAccessCache
    private let isLegacyUserCacheKey = SkyConstants.UserDefaults.isLegacyUserCache
    
    // 是否拥有完整版权限 (购买了内购 OR 老用户)
    @Published var hasAccess: Bool = false {
        didSet {
            // 自动缓存到本地,支持离线使用
            UserDefaults.standard.set(hasAccess, forKey: hasAccessCacheKey)
            print("💾 hasAccess cached: \(hasAccess)")
        }
    }
    
    @Published var isPurchasing: Bool = false
    @Published var loadError: String? = nil
    @Published var isLegacyUser: Bool = false {
        didSet {
            // 缓存老用户状态
            UserDefaults.standard.set(isLegacyUser, forKey: isLegacyUserCacheKey)
            print("💾 isLegacyUser cached: \(isLegacyUser)")
        }
    }
    
    private enum LoadProductsError: Error {
        case timeout
    }
    
    // 通用查询接口: 检查是否已购买某商品
    func isPurchased(_ productID: String) -> Bool {
        // 1. 如果是解锁完整版,需要考虑老用户权限
        if productID == IAPPack.unlockGame.rawValue {
            return hasAccess
        }
        // 2. 其他商品(如皮肤)直接查已购列表
        return purchasedProductIDs.contains(productID)
    }
    
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil
    
    private override init() {
        super.init()
        self.updates = observeTransactionUpdates()
        
        // 🔥 优先从本地缓存恢复状态 (支持离线使用)
        self.hasAccess = UserDefaults.standard.bool(forKey: hasAccessCacheKey)
        self.isLegacyUser = UserDefaults.standard.bool(forKey: isLegacyUserCacheKey)
        print("📱 Restored from cache - hasAccess: \(hasAccess), isLegacyUser: \(isLegacyUser)")
        
        // 后台异步更新在线状态 (不阻塞启动)
        Task {
            await checkLegacyAccess()
            await updatePurchasedProducts()
            // 顺便预加载商品信息 (失败也不影响主流程)
            try? await loadProducts()
        }
    }
    
    deinit {
        self.updates?.cancel()
    }
    
    // MARK: - Legacy User Check
    func checkLegacyAccess() async {
        // 如果缓存已经是 true，就不必重复查 AppTransaction 了，但要触发一次权限重算保底
        if UserDefaults.standard.bool(forKey: isLegacyUserCacheKey) {
            await MainActor.run {
                self.isLegacyUser = true
                self.hasAccess = true
            }
            return
        }
        
        do {
            let result = try await AppTransaction.shared
            
            if case .verified(let appTransaction) = result {
                let originalPurchaseDate = appTransaction.originalPurchaseDate
                print("📝 原始购买时间: \(originalPurchaseDate)")
                
                // 📅 截止时间：2026-01-03 02:29 (北京时间 UTC+8) = 2026-01-02 18:29 (UTC)
                var components = DateComponents()
                components.year = 2026
                components.month = 1
                components.day = 2
                components.hour = 18    // UTC 18点
                components.minute = 29 // UTC 29分
                components.timeZone = TimeZone(identifier: "UTC")
                
                let calendar = Calendar(identifier: .gregorian)
                
                // 边界情况处理：如果创建失败，默认判定为新用户（更安全）
                guard let cutoffDate = calendar.date(from: components) else {
                    print("⚠️ cutoffDate 创建失败，默认判定为新用户")
                    await MainActor.run {
                        self.isLegacyUser = false
                    }
                    return
                }
                
                print("📅 截止时间 (UTC): \(cutoffDate)")
                
                if originalPurchaseDate < cutoffDate {
                    print("🎉 判定为老用户 (购买时间 < 截止时间)")
                    await MainActor.run {
                        self.isLegacyUser = true
                        self.hasAccess = true
                    }
                } else {
                    print("🆕 判定为新用户 (购买时间 >= 截止时间)")
                    await MainActor.run {
                        self.isLegacyUser = false
                    }
                }
            } else {
                print("⚠️ AppTransaction 验证失败")
            }
        } catch {
            print("❌ 老用户验证出错: \(error)")
        }
    }
    
    // MARK: - Load Products
    func loadProducts() async throws {
        // 如果已经加载到商品了，就不重复加载
        guard !self.productsLoaded || self.products.isEmpty else { return }
        
        // 清除之前的错误
        await MainActor.run { self.loadError = nil }
        
        do {
            let fetchedProducts = try await fetchProductsWithTimeout()
            await MainActor.run {
                self.products = fetchedProducts
                // 只有加载到商品才标记为已加载
                if !fetchedProducts.isEmpty {
                    self.productsLoaded = true
                }
                self.loadError = nil
            }
            print("✅ Products loaded successfully: \(self.products.count) products")
            
            // 如果加载到 0 个商品，提示可能的原因
            if fetchedProducts.isEmpty {
                print("⚠️ Loaded 0 products. Possible reasons: no network permission, product IDs not configured")
                await MainActor.run {
                    self.loadError = "请检查网络权限或稍后重试"
                }
            }
        } catch {
            if case LoadProductsError.timeout = error {
                print("⏳ Load products timeout")
                await MainActor.run {
                    self.loadError = "连接超时，请重试"
                }
                throw error
            }
            
            print("❌ Failed to load products: \(error)")
            await MainActor.run {
                self.loadError = "网络连接失败，请检查网络"
            }
            throw error
        }
    }

    private func fetchProductsWithTimeout(
        timeoutSeconds: UInt64 = 8
    ) async throws -> [Product] {
        try await withThrowingTaskGroup(of: [Product].self) { group in
            group.addTask { [productIds] in
                try await Product.products(for: productIds)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                throw LoadProductsError.timeout
            }
            
            let result = try await group.next()
            group.cancelAll()
            return result ?? []
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        guard !isPurchasing else {
            print("⚠️ Purchase already in progress")
            return
        }
        
        await MainActor.run { isPurchasing = true }

        defer {
          Task { @MainActor in isPurchasing = false }
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                print("✅ Purchase successful: \(transaction.productID)")
                
                await self.updatePurchasedProducts()
                
                NotificationCenter.default.post(
                    name: .didPurchaseSuccess,
                    object: transaction.productID
                )
                
                await transaction.finish()
                
            case let .success(.unverified(transaction, error)):
                print("⚠️ Purchase unverified: \(error)")
                await transaction.finish()
                throw PurchaseError.verificationFailed
                
            case .pending:
                print("⏳ Purchase pending")
                throw PurchaseError.purchaseFailed(
                    NSLocalizedString("购买需要确认", comment: "")
                )
                
            case .userCancelled:
                print("🚫 Purchase cancelled by user")
                throw PurchaseError.userCancelled
                
            @unknown default:
                print("❓ Unknown purchase result")
                throw PurchaseError.purchaseFailed(
                    NSLocalizedString("未知错误", comment: "")
                )
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            NotificationCenter.default.post(
                name: .didPurchaseFail,
                object: error
            )
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws -> Bool {
        let previousPurchasedCount = purchasedProductIDs.count
        
        // 同时重新检查老用户资格
        await checkLegacyAccess()
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            let hasNewPurchases = purchasedProductIDs.count > previousPurchasedCount
            
            NotificationCenter.default.post(
                name: .didRestorePurchases,
                object: hasNewPurchases
            )
            
            print("✅ Purchases restored successfully. New: \(hasNewPurchases)")
            return hasNewPurchases
            
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            throw error
        }
    }
    
    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        var newPurchasedIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                newPurchasedIDs.insert(transaction.productID)
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = newPurchasedIDs
            
            // 如果已经是老用户，hasAccess 保持 true
            // 否则，看内购
            if self.isLegacyUser {
                self.hasAccess = true
            } else if newPurchasedIDs.contains(IAPPack.unlockGame.rawValue) {
                self.hasAccess = true
            } else if newPurchasedIDs.isEmpty &&
                        UserDefaults.standard.bool(forKey: hasAccessCacheKey) {
                // 离线/未同步时保留本地缓存，避免冷启动误判为未购买
                self.hasAccess = true
            } else {
                self.hasAccess = false
            }
            
            print("📊 Entitlements Updated. Has Access: \(self.hasAccess)")
        }
    }
    
    // MARK: - Observe Transaction Updates
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                guard case .verified(let transaction) = verificationResult else {
                    continue
                }
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
}
