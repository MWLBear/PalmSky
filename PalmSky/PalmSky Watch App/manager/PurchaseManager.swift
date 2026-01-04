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
    @Published var isLegacyUser: Bool = false {
        didSet {
            // 缓存老用户状态
            UserDefaults.standard.set(isLegacyUser, forKey: isLegacyUserCacheKey)
            print("💾 isLegacyUser cached: \(isLegacyUser)")
        }
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
            await updatePurchasedProducts()
            await checkLegacyAccess()
            // 顺便预加载商品信息 (失败也不影响主流程)
            try? await loadProducts()
        }
    }
    
    deinit {
        self.updates?.cancel()
    }
    
    // MARK: - Legacy User Check
    func checkLegacyAccess() async {
        do {
            let shared = try await AppTransaction.shared
            
            if case .verified(let appTransaction) = shared {
                let originalVersion = appTransaction.originalAppVersion
             
              print("📝 Original App Version: \(originalVersion)")

              
                // 解析版本号 (e.g. "1.0", "1.2.3")
                let versionComponents = originalVersion.split(separator: ".")
                
                if let majorString = versionComponents.first, let major = Int(majorString) {
                     print("📝 Original App Version: \(originalVersion) (Major: \(major))")
                    
                    if major < SkyConstants.newBusinessModelMajorVersion {
                        // 老用户：直接赋予权限
                        await MainActor.run {
                            self.isLegacyUser = true
                            self.hasAccess = true
                        }
                        print("🎉 Legacy User Detected! Access Granted.")
                    } else {
                        await MainActor.run {
                            self.isLegacyUser = false
                        }
                        // hasAccess 取决于是否购买了 IAP，在 updatePurchasedProducts 更新
                         print("🆕 New User Detected.")
                    }
                } else {
                     print("⚠️ Failed to parse original version: \(originalVersion)")
                }
            } else {
                 print("⚠️ Unverified App Transaction")
            }
        } catch {
            print("❌ Failed to get AppTransaction: \(error)")
        }
    }
    
    // MARK: - Load Products
    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        
        do {
            let fetchedProducts = try await Product.products(for: productIds)
            await MainActor.run {
                self.products = fetchedProducts
                self.productsLoaded = true
            }
            print("✅ Products loaded successfully: \(self.products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            throw error
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
            } else {
                self.hasAccess = newPurchasedIDs.contains(IAPPack.unlockGame.rawValue)
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

