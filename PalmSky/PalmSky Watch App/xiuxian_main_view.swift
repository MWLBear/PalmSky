
import SwiftUI

// MARK: - 1. 灵气粒子特效 (营造氛围)
struct ParticleView: View {
    let color: Color
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedY: CGFloat
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: 4 * particle.scale, height: 4 * particle.scale)
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .onChange(of: timeline.date) { _ in updateParticles() }
        }
        .onAppear {
            // 初始生成一些粒子
            for _ in 0..<15 { particles.append(createParticle()) }
        }
    }
    
    func updateParticles() {
        for i in particles.indices {
            particles[i].y -= particles[i].speedY
            particles[i].opacity -= 0.005
        }
        // 移除消失的，补充新的
        particles.removeAll { $0.opacity <= 0 || $0.y < 0 }
        if Float.random(in: 0...1) < 0.1 && particles.count < 20 {
            particles.append(createParticle())
        }
    }
    
    func createParticle() -> Particle {
        Particle(
            x: CGFloat.random(in: 0.2...0.8),
            y: 1.0, // 从底部升起
            scale: CGFloat.random(in: 0.5...1.5),
            opacity: Double.random(in: 0.3...0.7),
            speedY: CGFloat.random(in: 0.002...0.005)
        )
    }
}


struct MainView: View {
    @StateObject private var gameManager = GameManager.shared
    @State private var showSettings = false
    @State private var showBreakthrough = false
    @Environment(\.scenePhase) var scenePhase

  
    // 动画状态
    @State private var pulse = false
    
    var body: some View {
        GeometryReader { geo in
            // 核心尺寸计算
            let screenWidth = geo.size.width
            let ringSize = screenWidth * 0.90 // 圆环撑满 90% 屏幕
            let taijiSize = screenWidth * 0.58 // 太极占 58%
            
            let colors = RealmColor.gradient(for: gameManager.player.level)
            let primaryColor = colors.last ?? .green
            
            ZStack {
                // 1. 全局背景 (纯黑 + 底部微光)
                Color.black.ignoresSafeArea()
                
                // 底部氛围光 (让底部数据不那么单调)
                RadialGradient(
                    gradient: Gradient(colors: [primaryColor.opacity(0.2), .clear]),
                    center: UnitPoint(x: 0.5, y: 0.9), // 光源在底部
                    startRadius: 20,
                    endRadius: screenWidth * 0.6
                )
                .ignoresSafeArea()
                
                // 灵气粒子 (保留氛围)
                ParticleView(color: primaryColor)
                    .opacity(0.6) //稍微降低不抢视觉
                
                // 2. 核心圆环层 (撑满屏幕)
                ZStack {
                    // 轨道 (暗色背景)
                    Circle()
                        .trim(from: 0.16, to: 0.84) // 底部留开口 (开口大小调整为合适放置数字)
                        .stroke(
                            Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round) // 加粗线条
                        )
                        .rotationEffect(.degrees(90))
                        .frame(width: ringSize, height: ringSize)
                    
                    if gameManager.getCurrentProgress() > 0 {
                      Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .shadow(color: .white, radius: 4)
                      // 🔴 修改这里：从 y 改为 x，数值为正
                      // 这样它的初始位置就是 3点钟方向 (0度)，与 SwiftUI 默认坐标系一致
                        .offset(x: ringSize / 2)
                        .rotationEffect(.degrees(90 + (360 * (0.16 + 0.68 * gameManager.getCurrentProgress()))))
                    }
                  
                    // 进度条 (亮色)
                    Circle()
                        .trim(from: 0.16, to: 0.16 + (0.68 * gameManager.getCurrentProgress()))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [colors.first!, primaryColor]),
                                center: .center,
                                startAngle: .degrees(90),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(90))
                        .shadow(color: primaryColor.opacity(0.6), radius: 8) // 发光效果增强
                        .frame(width: ringSize, height: ringSize)
                        .animation(.spring(response: 0.5), value: gameManager.getCurrentProgress())
                }
                .offset(y: 20)
                
                // 3. 物理太极 (居中)
                TaijiView(level: gameManager.player.level, onTap: {
                    gameManager.onTap()
                    // 点击时的缩放反馈
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        pulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pulse = false
                    }
                })
                .frame(width: taijiSize, height: taijiSize)
                .scaleEffect(pulse ? 1.08 : 1.0) // 更有力的跳动
                .offset(y: 20)
              
                // 4. 信息层 (Text Overlay)
                VStack {
              
                  ZStack {
                     
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                      // 境界名称
                      Text(gameManager.getRealmShort())
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: primaryColor.opacity(0.8), radius: 8)
                      
                      // Lv 胶囊 (像徽章一样跟在后面)
                      Text(gameManager.getLayerName())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(primaryColor.opacity(0.25))
                        .clipShape(Capsule())
                      // 稍微往上提一点，视觉对齐
                        .offset(y: -4)
                    }
                    
                  }
                 .padding(.top, 20)
                  
            
                    Spacer()
                    
                    // --- 底部：数据聚合 ---
                    // 放在圆环缺口处
                    VStack(spacing: 4) {
                      
                     if gameManager.showBreakButton {
                            // 突破模式：闪烁按钮
                          Button(action: {
                            showBreakthrough = true
                          }) {
                                Text("立即突破")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                    .background(
                                      LinearGradient(colors: [primaryColor, primaryColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: primaryColor.opacity(0.5), radius: 8)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 5)
                        } else {
                        
                           let isApproaching = gameManager.getCurrentProgress() >= 0.90
                            // 正常模式：数值 + 等级
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                // 灵力数值 (超大)
                                Text(gameManager.player.currentQi.xiuxianString)
                                    .font(.system(size: 26, weight: .bold, design: .rounded)) // 特大号数字
                                    .foregroundColor(isApproaching ? primaryColor : .white)
                                    .contentTransition(.numericText())
                                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1) // 描边阴影
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)

                                // 单位
                                Text("灵气")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.6)) // 半透明白
                                    .padding(.bottom, 4)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .ignoresSafeArea() // 这一步很关键，允许文字推到最边缘
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toast(message: $gameManager.offlineToastMessage)

        .onAppear { gameManager.startGame() }
        .onLongPressGesture { showSettings = true }
        .sheet(isPresented: $showBreakthrough) { BreakthroughView(isPresented: $showBreakthrough) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $gameManager.showEventView) {
            if let event = gameManager.currentEvent { EventView(event: event) }
        }
      // body 底部添加
      .onChange(of: scenePhase) { newPhase in
          if newPhase == .active {
              // App 回到前台，计算离线收益
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              gameManager.calculateOfflineGain()
            }
          } else if newPhase == .background {
              // App 切后台，保存时间
              gameManager.savePlayer()
          }
      }
      
    }
}

struct QiRippleEffect: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Layer 1: 内圈 - 高频灵力 (密集短点)
            // 模拟核心能量的高频振动
            Circle()
                .strokeBorder(
                    color.opacity(0.9),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 10])
                )
                .frame(width: 60, height: 60)
            
            // Layer 2: 主阵法 - 符文轨迹 (长虚线 + 角度渐变)
            // 模拟旋转时的拖尾光效
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            color,              // 头 (亮)
                            color.opacity(0.5), // 身 (半透)
                            color.opacity(0)    // 尾 (隐形)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [15, 25])
                )
                .frame(width: 100, height: 100)
            
            // Layer 3: 外圈 - 扩散余波 (细虚线)
            // 增加层次感和范围感
            Circle()
                .strokeBorder(
                    color.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, lineCap: .butt, dash: [5, 5])
                )
                .frame(width: 90, height: 90)
        }
    }
}

struct TaijiView: View {
    let level: Int
    let onTap: () -> Void
    
    // MARK: - Physics State
    @State private var rotation: Double = 0
    @State private var extraVelocity: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var lastTime: Date = Date()
    
    // MARK: - Wave Data (升级：增加旋转属性)
    struct QiWave: Identifiable {
        let id = UUID()
        var scale: CGFloat = 0.2
        var opacity: Double = 1.0
        var rotation: Double = Double.random(in: 0...360) // 初始随机角度
        // 🚀 修改：方向统一为正数 (顺时针)，与太极一致
        // 速度设定在 90~180 之间，既有快慢变化，又保持同向流动
        var rotationSpeed: Double = Double.random(in: 90...180)
    }
    @State private var waves: [QiWave] = []
    
    // Constants
    private var baseVelocity: Double {
        let stage = Double((level - 1) / 9)
        return 30.0 + (stage * 5.0)
    }
    private let maxVelocity: Double = 1080.0
    private let tapImpulse: Double = 250.0 // 稍微加大冲量
    private let decayFactor: Double = 2.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date
            let colors = RealmColor.gradient(for: level)
            let primaryColor = colors.last ?? .green
            
            ZStack {
                // 1. 境界背景光 (呼吸)
                let energyRatio = min(extraVelocity / 800.0, 1.0)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                primaryColor.opacity(0.2 + energyRatio * 0.3),
                                primaryColor.opacity(0.05),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 100 + (energyRatio * 40)
                        )
                    )
                    .scaleEffect(1.0 + sin(now.timeIntervalSince1970 * 2.5) * 0.03)
                
                // 2. ✨✨✨ 灵力涟漪 (使用新组件) ✨✨✨
                ForEach(waves) { wave in
                    QiRippleEffect(color: primaryColor)
                        .rotationEffect(.degrees(wave.rotation)) // 气旋自转
                        .scaleEffect(wave.scale)                 // 扩散
                        .opacity(wave.opacity)                   // 渐隐
                        // 🔥 关键：滤色模式，让光效叠加变亮，更有能量感
                        .blendMode(.screen)
                }
                
                // 3. 太极主体
                Image("TaiChi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .shadow(
                        color: primaryColor.opacity(0.5 + energyRatio * 0.5),
                        radius: 10 + (energyRatio * 15)
                    )
            }
            .contentShape(Circle())
            .onTapGesture { handleTap() }
            .onChange(of: now) { newDate in updatePhysics(currentTime: newDate) }
        }
    }
    
    // MARK: - Physics Logic
    private func updatePhysics(currentTime: Date) {
        let deltaTime = currentTime.timeIntervalSince(lastTime)
        lastTime = currentTime
        
        // 旋转与阻尼
        let currentVelocity = baseVelocity + extraVelocity
        rotation += currentVelocity * deltaTime
        
        if extraVelocity > 0 {
            extraVelocity -= extraVelocity * decayFactor * deltaTime
            if extraVelocity < 1.0 { extraVelocity = 0 }
        }
        
        // 更新波纹状态
        for i in waves.indices.reversed() {
            // 扩散速度 (稍微快一点，爆发感)
            waves[i].scale += 3.5 * deltaTime
            // 消失速度
            waves[i].opacity -= 1.5 * deltaTime
            // 气旋旋转
            waves[i].rotation += waves[i].rotationSpeed * deltaTime
            
            if waves[i].opacity <= 0 {
                waves.remove(at: i)
            }
        }
        
        // 按压回弹
        if scale > 1.0 {
            scale -= 3.0 * deltaTime
            if scale < 1.0 { scale = 1.0 }
        }
    }
    
    private func handleTap() {
        if (baseVelocity + extraVelocity + tapImpulse) < maxVelocity {
            extraVelocity += tapImpulse
        }
        scale = 1.15 // 按压幅度大一点，手感好
        waves.append(QiWave())
        onTap()
    }
}

