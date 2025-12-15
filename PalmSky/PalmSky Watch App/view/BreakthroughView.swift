import SwiftUI

// MARK: - 灵气粒子系统
struct QiParticle: Identifiable {
    let id = UUID()
    var angle: Double       // 角度
    var distance: CGFloat   // 距离中心的距离
    var speed: CGFloat      // 飞行速度
    var size: CGFloat       // 粒子大小
    var opacity: Double     // 透明度
}

struct BreakthroughView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager

    // --- 动画状态 ---
    @State private var isAttempting = false
    // 1. 聚气粒子
    @State private var particles: [QiParticle] = []
    // 2. 核心能量球
    @State private var coreScale: CGFloat = 1.0
    @State private var coreBrightness: Double = 0.0
    @State private var coreRotation: Double = 0.0
    // 3. 冲击波
    @State private var shockwaveScale: CGFloat = 0.0
    @State private var shockwaveOpacity: Double = 0.0
    // 4. 全屏闪光
    @State private var flashOpacity: Double = 0.0
    
    @State private var buttonProgress: CGFloat = 0.0 // 按钮进度 (0.0 - 1.0)

  
    // 结果
    @State private var result: BreakthroughResult?
    @State private var showResultView = false
    
    enum BreakthroughResult {
        case success
        case failure
    }
    
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            
            let colors = RealmColor.gradient(for: gameManager.player.level)
            let primaryColor = colors.last ?? .green
            
            ZStack {
                // 1. 深邃背景
                Color.black.ignoresSafeArea()
                
              // 底部氛围光 (让底部数据不那么单调)
              RadialGradient(
                  gradient: Gradient(colors: [primaryColor.opacity(0.2), .clear]),
                  center: UnitPoint(x: 0.5, y: 0.5), // 光源在底部
                  startRadius: 20,
                  endRadius: width
              )
              .ignoresSafeArea()
              
                if !showResultView {
                    VStack(spacing: 0) {
                        
                        // MARK: - 视觉核心区域 (法阵 + 粒子)
                        Spacer().frame(height: 40)
                        
                        ZStack {
                            // A. 静态底轨 (极简)
                            Circle()
                                .trim(from: 0.15, to: 0.85)
                                .stroke(primaryColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(90))
                                .frame(width: width * 0.75, height: width * 0.75)
                            
                            // B. 境界文字 (平时显示，突破时隐去)
                            if !isAttempting {
                                VStack(spacing: 4) {
                                    Text(gameManager.getRealmShort())
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: primaryColor, radius: 10)
                                    
                                    Text(gameManager.getLayerName())
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(primaryColor.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .transition(.opacity)
                            }
                            
                            // C. ✨ 灵气汇聚粒子 (只在突破时出现)
                            ForEach(particles) { p in
                                Circle()
                                    .fill(primaryColor)
                                    .frame(width: p.size, height: p.size)
                                    .opacity(p.opacity)
                                    // 极坐标转换：根据角度和距离算出位置
                                    .offset(
                                        x: cos(p.angle) * p.distance,
                                        y: sin(p.angle) * p.distance
                                    )
                            }
                            
                            // D. ✨ 核心丹田 (聚气时出现)
                            if isAttempting {
                                ZStack {
                                    // 外层光晕 (高速旋转)
                                    Circle()
                                        .fill(
                                            AngularGradient(colors: [primaryColor.opacity(0), primaryColor], center: .center)
                                        )
                                        .frame(width: 80, height: 80)
                                        .rotationEffect(.degrees(coreRotation))
                                        .blur(radius: 5)
                                    
                                    // 内核 (高亮压缩)
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: primaryColor, radius: 10 + coreBrightness * 20) // 越压缩越亮
                                        .scaleEffect(coreScale)
                                }
                            }
                            
                            // E. ✨ 冲击波 (爆发时出现)
                            Circle()
                                .stroke(Color.white, lineWidth: 20) // 也是光圈
                                .frame(width: 50, height: 50)
                                .scaleEffect(shockwaveScale)
                                .opacity(shockwaveOpacity)
                            
                        }
                        .frame(width: width, height: width) // 容器区、
                        .offset(y: 10)
                        .ignoresSafeArea()
                        
                        
                        // MARK: - 底部操作
                        VStack(spacing: 0) {
                            if !isAttempting {
                                Text("共鸣率 \(Int(GameLevelManager.shared.breakSuccess(level: gameManager.player.level) * 100))%")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 12)
                            } else {
                                Text("天地灵气汇聚中...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(primaryColor)
                                    .padding(.bottom, 12)
                            }
                            
                            Button(action: startBreakthrough) {
                                Text(isAttempting ? "突破中..." : "逆天改命")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 6)
                                    .background(
                                      LinearGradient(colors: [primaryColor, primaryColor.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: primaryColor.opacity(0.5), radius: 8)

                                    .overlay(
                                        // 突破时按钮变成进度条既视感
                                        Group {
                                            if isAttempting {
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(isAttempting)
                        }
                        .offset(y: -70)
                    
                    }
                    .ignoresSafeArea()
                    
                } else {
    
                  VStack(spacing: 0) {
                    Spacer().frame(height: 30)

                      Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                          .font(.system(size: 60))
                          .foregroundColor(result == .success ? primaryColor : .red)
                          .symbolEffect(.bounce, value: showResultView)
                          .padding(.bottom, 15)
                    
                      
                      VStack(spacing: 4) {
                          Text(result == .success ? "突破成功" : "突破失败")
                              .font(.system(size: 24, weight: .bold, design: .rounded))
                              .foregroundColor(.white)
                          
                          if result == .success {
                              Text(gameManager.getCurrentRealm())
                                  .font(.system(size: 18, weight: .medium))
                                  .foregroundColor(primaryColor)
                          } else {
                             
                              Text("道心受损 -\(gameManager.currentPenaltyPercentage)%")
                                  .font(.system(size: 14))
                                  .foregroundColor(.gray)
                          }
                      }
                      
                      Spacer()
                      Button(action: { isPresented = false }) {
                          Text("完成")
                              .font(.system(size: 16, weight: .medium))
                              .padding(.horizontal, 50)
                              .padding(.vertical, 8)
                              .background(
                                LinearGradient(colors: [primaryColor, primaryColor.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                              )
                              .clipShape(Capsule())
                              .shadow(color: primaryColor.opacity(0.5), radius: 8)

                      }
                      .buttonStyle(.plain)
                      .padding(.bottom, 20)
                    
                    Spacer()

                  }
                  .ignoresSafeArea()
                }
                
                // 闪光层
                Color.white.ignoresSafeArea().opacity(flashOpacity).allowsHitTesting(false)
            }
            .onReceive(timer) { _ in
                updateParticles()
            }
        }
    }
    
    // MARK: - ✨ 粒子与动画逻辑
    private func startBreakthrough() {
        withAnimation { isAttempting = true }
        
        // 1. 开始生成聚气粒子
        // 逻辑在 updateParticles() 里，这里只需要打开开关
        
        withAnimation(.linear(duration: 2.0)) {
          buttonProgress = 1.0
        }
      
        // 2. 核心凝练动画 (2秒)
        // 从 1.0 压缩到 0.2 (密度极大)，亮度飙升
        withAnimation(.easeIn(duration: 2.0)) {
            coreScale = 0.2
            coreBrightness = 1.0
        }
        // 核心旋转加速
        withAnimation(.linear(duration: 2.0)) {
            coreRotation = 720
        }
        
        // 震动反馈 (越来越快)
        for i in 0..<10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
               HapticManager.shared.playIfEnabled(.click)
            }
        }
        
        // 3. 爆发时刻 (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 清空粒子
            particles.removeAll()
            
            // 冲击波扩散
            shockwaveOpacity = 1.0
            withAnimation(.easeOut(duration: 0.3)) {
                shockwaveScale = 20.0 // 扩得非常大，冲出屏幕
                shockwaveOpacity = 0.0
            }
            
            // 白光一闪
            withAnimation(.easeOut(duration: 0.05)) { flashOpacity = 1.0 }
            
            // 结算
            let success = gameManager.attemptBreak()
            result = success ? .success : .failure
            HapticManager.shared.playIfEnabled(success ? .success : .failure)
            withAnimation { showResultView = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.1)) { flashOpacity = 0.0 }
        }
    }
    
    // 每帧刷新粒子
    private func updateParticles() {
        guard isAttempting else { return }
        
        // 1. 生成新粒子 (从屏幕边缘生成)
        for _ in 0..<3 { // 每帧生成3个
            let angle = Double.random(in: 0...(2 * .pi))
            let p = QiParticle(
                angle: angle,
                distance: 120, // 初始距离
                speed: CGFloat.random(in: 3...6), // 飞行速度
                size: CGFloat.random(in: 2...4),
                opacity: 0.0
            )
            particles.append(p)
        }
        
        // 2. 更新现有粒子
        for i in particles.indices {
            particles[i].distance -= particles[i].speed // 向中心移动
            particles[i].speed += 0.2 // 加速被吸入
            
            // 透明度变化：出生渐显 -> 靠近中心渐隐
            if particles[i].distance > 100 {
                particles[i].opacity = min(1.0, particles[i].opacity + 0.1)
            } else if particles[i].distance < 20 {
                particles[i].opacity -= 0.2
            }
        }
        
        // 3. 移除死粒子 (被吸入丹田)
        particles.removeAll { $0.distance <= 0 || $0.opacity <= 0 }
    }
}


#Preview {
  BreakthroughView(isPresented: .constant(true))
}
