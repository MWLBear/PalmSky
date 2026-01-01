import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 动态呼吸状态
    @State private var isAnimating = false
    
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
                        BenefitRow( icon: "applewatch.watchface",  title: "表盘显化",subtitle: "表盘组件，实时进度",color: .cyan)
                        Divider()
                        BenefitRow(icon: "infinity", title: "百世轮回", subtitle: "开启转世，继承天赋", color: .purple)
                        Divider()

                    }
                    .padding(.horizontal, 8)
                    
                    Spacer(minLength: 0)
                    
                    // MARK: - 3. 购买按钮
                    if purchaseManager.isPurchasing {
                        ProgressView()
                            .tint(.orange)
                            .padding()
                    } else {
                        if let product = purchaseManager.products.first {
                            Button {
                                buy(product)
                            } label: {
                                Text("结成契约 \(product.displayPrice)")
                                    .font(XiuxianFont.secondaryButton)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    // 呼吸阴影
                                    .shadow(color: .orange.opacity(isAnimating ? 0.6 : 0.3), radius: isAnimating ? 10 : 5)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                        } else {
                            // 加载中
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 40)
                                .overlay(Text("正在连接天道...").font(.caption).foregroundColor(.gray))
                                .padding(.horizontal, 12)
                                .task { try? await purchaseManager.loadProducts() }
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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
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
