import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // 1. 背景：保持深邃黑，加一点点底部的氛围光
            Color.black.ignoresSafeArea()
            
            // 底部黄色光晕
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.15),
                    Color.black
                ]),
                center: .bottom,
                startRadius: 50,
                endRadius: 200
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    
                    // MARK: - 1. 头部核心视觉
                    VStack(spacing: 12) {
                        // 一个精致的大图标
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                        
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("watch_paywall_title", comment: ""))
                                .font(XiuxianFont.realmTitle)
                                .foregroundColor(.white)
                            
                            Text(NSLocalizedString("watch_paywall_subtitle", comment: ""))
                                .font(XiuxianFont.body)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // MARK: - 2. 权益列表 (回归经典的垂直列表)
                    // 这种排版在手表上最清晰，最高级
                    VStack(alignment: .leading, spacing: 8) {
                        
//                        BenefitRow(icon: "crown.fill", title: "境界全开", subtitle: "突破金丹，直指九天", color: .yellow)
                      // lV10 付费墙
                        BenefitRow(icon: "crown.fill", title: NSLocalizedString("watch_paywall_benefit_realm_title", comment: ""), subtitle: NSLocalizedString("watch_paywall_benefit_realm_subtitle", comment: ""), color: .yellow)
                        Divider()
                        BenefitRow(icon: "bolt.horizontal.circle.fill", title: NSLocalizedString("watch_paywall_benefit_auto_break_title", comment: ""), subtitle: NSLocalizedString("watch_paywall_benefit_auto_break_subtitle", comment: ""), color: .orange) // ✨ 新增
                        Divider()
                        BenefitRow(icon: "clock.fill", title: NSLocalizedString("watch_paywall_benefit_offline_title", comment: ""), subtitle: NSLocalizedString("watch_paywall_benefit_offline_subtitle", comment: ""), color: .blue)
                        Divider()
                        BenefitRow(icon: "figure.walk", title: NSLocalizedString("watch_paywall_benefit_steps_title", comment: ""), subtitle: NSLocalizedString("watch_paywall_benefit_steps_subtitle", comment: ""), color: .green)
                        Divider()
                      
                        #if os(watchOS)
                        BenefitRow( icon: "applewatch.watchface",  title: NSLocalizedString("watch_paywall_benefit_widget_watch_title", comment: ""),subtitle: NSLocalizedString("watch_paywall_benefit_widget_watch_subtitle", comment: ""),color: .cyan)
                        #elseif os(iOS)
                        BenefitRow( icon: "applewatch.watchface",  title: NSLocalizedString("watch_paywall_benefit_widget_ios_title", comment: ""),subtitle: NSLocalizedString("watch_paywall_benefit_widget_ios_subtitle", comment: ""),color: .cyan)
                        #endif
        
                        Divider()
                        BenefitRow(icon: "infinity", title: NSLocalizedString("watch_paywall_benefit_reincarnation_title", comment: ""), subtitle: NSLocalizedString("watch_paywall_benefit_reincarnation_subtitle", comment: ""), color: .purple)
                        Divider()
                      
                         HStack {
                             Spacer()
                             Text(NSLocalizedString("watch_paywall_one_purchase", comment: ""))
                                 .font(XiuxianFont.caption)
                                 .foregroundColor(.gray)
                                 .padding(.top, 8)
                             Spacer()
                         }
        

                    }
                    .padding(.horizontal, 8)
                    
                    Spacer(minLength: 0)
                    
                    // MARK: - 3. 购买按钮
                    if let product = purchaseManager.unlockProduct {
                      Button {
                        // 1. 立即震动 (防止审核员觉得没反应)
                        HapticManager.shared.playIfEnabled(.click)
                        
                        // 2. 发起购买
                        if !purchaseManager.isPurchasing {
                          buy(product)
                        }
                      } label: {
                        ZStack {
                          // --- Layer A: 统一的背景 ---
                          // 无论是否加载中，背景都一样，保证视觉稳定性
                          LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                          .clipShape(Capsule())
                          
                          // --- Layer B: 内容切换 ---
                          if purchaseManager.isPurchasing {
                            // 状态 A: 加载中
                            HStack(spacing: 6) {
                              ProgressView()
                                .tint(.white) // 白色转圈
                                .scaleEffect(0.8) // 稍微调小一点适配高度
                                .frame(width: 15, height: 15)
                              
                              Text(NSLocalizedString("watch_paywall_connecting", comment: ""))
                                .font(XiuxianFont.secondaryButton)
                                .foregroundColor(.white)
                            }
                          } else {
                            // 状态 B: 正常价格
                            Text(String(format: NSLocalizedString("watch_paywall_buy_button_format", comment: ""), product.displayPrice ?? "..."))
                              .font(XiuxianFont.secondaryButton)
                              .foregroundColor(.white)
                          }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40) // 固定高度
                        // 阴影效果
                        .shadow(color: .orange.opacity(0.5), radius: 8)
                      }
                      .buttonStyle(.plain)
                      .padding(.horizontal, 12)
                      // 加载中禁用点击
                      .disabled(purchaseManager.isPurchasing)
                      
                    } else {
                      // 商品加载中占位
                      VStack(spacing: 12) {
                        if purchaseManager.loadError != nil {
                          // 错误状态：只显示重试按钮
                          Button {
                            Task { try? await purchaseManager.loadProducts() }
                          } label: {
                            Text(NSLocalizedString("watch_paywall_retry_connect", comment: ""))
                              .font(XiuxianFont.secondaryButton)
                              .foregroundColor(.white)
                              .frame(maxWidth: .infinity)
                              .frame(height: 40)
                              .background(Color.orange)
                              .clipShape(Capsule())
                          }
                          .buttonStyle(.plain)
                          .padding(.horizontal, 12)
                        } else {
                          // 加载中状态
                          RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 40)
                            .overlay(
                              Text(NSLocalizedString("watch_paywall_connecting_service", comment: ""))
                                .font(.caption)
                                .foregroundColor(.gray)
                            )
                            .padding(.horizontal, 12)
                        }
                      }
                      .task { try? await purchaseManager.loadProducts() }
                      .onChange(of: purchaseManager.loadError) { _, error in
                        if let error = error {
                          alertMessage = error
                          showingAlert = true
                        }
                      }
                    }
                    
                    // 4. 恢复购买 (极简)
                    Button(NSLocalizedString("watch_paywall_restore_existing", comment: "")) {
                        restore()
                    }
                    .font(XiuxianFont.body)
                    .frame(height: 40)
                    .foregroundColor(.gray)
                    .buttonStyle(.plain)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(NSLocalizedString("watch_common_tip", comment: "")), message: Text(alertMessage), dismissButton: .default(Text(NSLocalizedString("watch_common_ok", comment: ""))))
        }
        .onChange(of: purchaseManager.hasAccess) { _, hasAccess in
            if hasAccess {
                HapticManager.shared.playIfEnabled(.success)
                dismiss()
            }
        }
    }
    
    // Actions
    private func buy(_ product: Product) {
        Task {
            do { try await purchaseManager.purchase(product) }
            catch { alertMessage = error.localizedDescription; showingAlert = true }
        }
    }
    private func restore() {
        Task {
            do {
                let hasNew = try await purchaseManager.restorePurchases()
                alertMessage = hasNew ? NSLocalizedString("watch_paywall_restore_success", comment: "") : NSLocalizedString("watch_paywall_restore_not_found", comment: "")
                showingAlert = true
            } catch { alertMessage = error.localizedDescription; showingAlert = true }
        }
    }
}

// MARK: - 极简行视图 (Clean Row)
struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            // 文字
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                .font(XiuxianFont.secondaryButton)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(XiuxianFont.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
          
        }
        .contentShape(Rectangle()) // 优化点击区域(虽然这里不可点)
    }
}

#Preview(body: {
  PaywallView()
})

extension Product {
  
  var displayPrice: String? {
      return self.price.formatted(self.priceFormatStyle)
  }
  
}

struct ConsumableShopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameManager: GameManager
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var purchasingProductID: String?
    
    private let offerPrimaryFont: Font = .headline
    
    var body: some View {
        NavigationStack {
            List {
                // 通用消耗品商店：按道具类型分组，后续可继续扩展新品类
                ForEach(ConsumableKind.allCases, id: \.self) { kind in
                    let offers = purchaseManager.offers(for: kind)
                    if !offers.isEmpty {
                        Section(
                            header: sectionHeaderView(for: kind),
                            footer: Text(deviceScopedFooter)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        ) {
                            ForEach(offers) { offer in
                                offerRow(for: offer)
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("shop_nav_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                try? await purchaseManager.loadProducts()
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(NSLocalizedString("watch_common_tip", comment: "")),
                    message: Text(alertMessage),
                    dismissButton: .default(Text(NSLocalizedString("watch_common_ok", comment: "")))
                )
            }
        }
    }
    
    /// 单个商品卡片：负责展示数量、主推标记与价格
    @ViewBuilder
    private func offerRow(for offer: ConsumableOffer) -> some View {
        if let product = purchaseManager.product(for: offer) {
            Button {
                buy(product)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(offerTitle(for: offer))
                            .font(offerPrimaryFont)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        if offer.isFeatured {
                            Text(NSLocalizedString("shop_offer_featured_badge", comment: ""))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        Spacer(minLength: 0)
                    }
                    
                    HStack {
                        if purchasingProductID == product.id {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 40, alignment: .leading)
                        } else {
                            Text(product.displayPrice ?? "...")
                                .font(offerPrimaryFont)
                                .foregroundColor(.orange)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isPurchasing)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    Text(offerTitle(for: offer))
                        .font(offerPrimaryFont)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    if offer.isFeatured {
                        Text(NSLocalizedString("shop_offer_featured_badge", comment: ""))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    Spacer(minLength: 8)
                }
                
                HStack {
                    if let loadError = purchaseManager.loadError {
                        Text(loadError)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.trailing)
                    } else {
                        ProgressView()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    /// 根据当前运行平台返回“库存不互通”的说明文案
    private var deviceScopedFooter: String {
        // 文案明确说明库存按设备隔离，避免用户误解为账号互通
        #if os(watchOS)
        return NSLocalizedString("shop_device_scope_watch", comment: "")
        #else
        return NSLocalizedString("shop_device_scope_ios", comment: "")
        #endif
    }
    
    /// 读取当前端对应道具的库存
    private func inventoryCount(for kind: ConsumableKind) -> Int {
        switch kind {
        case .protectCharm:
            return gameManager.player.items.protectCharm
        }
    }
    
    /// 分组头：库存 + 道具作用说明
    @ViewBuilder
    private func sectionHeaderView(for kind: ConsumableKind) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(sectionHeader(for: kind))
                .font(.headline)
                .foregroundColor(.primary)
            Text(NSLocalizedString("shop_kind_protect_charm_shop_subtitle", comment: ""))
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .textCase(nil)
    }
    
    /// 分组标题：直接把库存合并进标题
    private func sectionHeader(for kind: ConsumableKind) -> String {
        switch kind {
        case .protectCharm:
            return String(
                format: NSLocalizedString("shop_inventory_header_format", comment: ""),
                inventoryCount(for: kind)
            )
        }
    }
    
    /// 商品主标题：中文顺序改成“数量 + 道具名”，减少小屏截断概率
    private func offerTitle(for offer: ConsumableOffer) -> String {
        String(
            format: NSLocalizedString("shop_offer_title_format", comment: ""),
            offer.quantity,
            NSLocalizedString(offer.kind.titleKey, comment: "")
        )
    }
    
    /// 发起购买；成功后关闭商店，失败则弹错误提示
    private func buy(_ product: Product) {
        Task {
            purchasingProductID = product.id
            do {
                try await purchaseManager.purchase(product)
                // 购买成功后直接关闭商店，回到原场景查看库存变化
                purchasingProductID = nil
                dismiss()
            } catch {
                purchasingProductID = nil
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}
