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
                            Text("飞升契约")
                                .font(XiuxianFont.realmTitle)
                                .foregroundColor(.white)
                            
                            Text("打破凡尘桎梏 · 证得无上大道")
                                .font(XiuxianFont.body)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // MARK: - 2. 权益列表 (回归经典的垂直列表)
                    // 这种排版在手表上最清晰，最高级
                    VStack(alignment: .leading, spacing: 8) {
                        
//                        BenefitRow(icon: "crown.fill", title: "境界全开", subtitle: "突破金丹，直指九天", color: .yellow)
                      // lV10 付费墙
                        BenefitRow(icon: "crown.fill", title: "境界解封", subtitle: "突破炼气，筑基成仙", color: .yellow)
                        Divider()
                        BenefitRow(icon: "bolt.horizontal.circle.fill", title: "自动冲关", subtitle: "解放双手，快速升级", color: .orange) // ✨ 新增
                        Divider()
                        BenefitRow(icon: "clock.fill", title: "闭关延时", subtitle: "离线挂机，十二小时", color: .blue)
                        Divider()
                        BenefitRow(icon: "figure.walk", title: "肉身成圣", subtitle: "单日炼化，四万步数", color: .green)
                        Divider()
                      
                        #if os(watchOS)
                        BenefitRow( icon: "applewatch.watchface",  title: "表盘显化",subtitle: "表盘组件，实时进度",color: .cyan)
                        #elseif os(iOS)
                        BenefitRow( icon: "applewatch.watchface",  title: "腕上天机",subtitle: "Apple Watch，专属表盘",color: .cyan)
                        #endif
        
                        Divider()
                        BenefitRow(icon: "infinity", title: "百世轮回", subtitle: "开启转世，继承天赋", color: .purple)
                        Divider()
                      
                         HStack {
                             Spacer()
                             Text("✨ 一次购买，双端通用")
                                 .font(XiuxianFont.caption)
                                 .foregroundColor(.gray)
                                 .padding(.top, 8)
                             Spacer()
                         }
        

                    }
                    .padding(.horizontal, 8)
                    
                    Spacer(minLength: 0)
                    
                    // MARK: - 3. 购买按钮
                    if let product = purchaseManager.products.first {
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
                              
                              Text("正在连接...")
                                .font(XiuxianFont.secondaryButton)
                                .foregroundColor(.white)
                            }
                          } else {
                            // 状态 B: 正常价格
                            Text("结成契约 \(product.displayPrice ?? "...")")
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
                            Text("重试连接")
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
                              Text("正在连接天道...")
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
                    Button("恢复已有契约") {
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
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("好的")))
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
                alertMessage = hasNew ? "恢复成功" : "未发现记录"
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
