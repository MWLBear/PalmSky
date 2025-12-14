import SwiftUI

struct RootPagerView: View {
    @EnvironmentObject var gameManager: GameManager

    @State private var page = 0
    @State private var showBreakthrough = false
  
    var body: some View {
        TabView(selection: $page) {
            
           MainView(showBreakthrough: $showBreakthrough)
                .tag(0)

            SettingsView()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      
        .sheet(isPresented: $showBreakthrough) {
          BreakthroughView(isPresented: $showBreakthrough)
        }
        .sheet(isPresented: $gameManager.showEventView) {
            if let event = gameManager.currentEvent {
                EventView(event: event)
            }
        }
      
    }
}

struct MainView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var showBreakthrough: Bool
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
//                Color.black.ignoresSafeArea()
//                
//                // 底部氛围光 (让底部数据不那么单调)
//                RadialGradient(
//                    gradient: Gradient(colors: [primaryColor.opacity(0.2), .clear]),
//                    center: UnitPoint(x: 0.5, y: 0.9), // 光源在底部
//                    startRadius: 20,
//                    endRadius: screenWidth * 0.6
//                )
//                .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                      primaryColor.opacity(0.2),  primaryColor.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
              
                // 灵气粒子 (保留氛围)
                ParticleView(color: primaryColor)
                    .opacity(0.6) //稍微降低不抢视觉
                
                // 2. 核心圆环层 (已封装)
                CultivationRingView(
                  ringSize: ringSize,
                  progress: gameManager.getCurrentProgress(),
                  primaryColor: primaryColor,
                  gradientColors: [colors.first ?? primaryColor, primaryColor]
                )
                .offset(y: 20) // 保持原有的偏移
           
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
                  
                  // ✅ 替换为封装好的组件
                  RealmHeaderView(
                    realmName: gameManager.getRealmShort(),
                    layerName: gameManager.getLayerName(),
                    primaryColor: primaryColor
                  )
                  
                  Spacer()
                  
                  // --- 底部：数据聚合 ---
                  VStack(spacing: 4) {
                    // 1. Buff 状态栏
                    BuffStatusBar()
                    
                    // 2. 核心操作区 (按钮 或 数值)
                    BottomControlView(
                      showBreakthrough: $showBreakthrough,
                      primaryColor: primaryColor
                    )
                  }
                }
                .ignoresSafeArea() // 这一步很关键，允许文字推到最边缘
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toast(message: $gameManager.offlineToastMessage)

        .onAppear { gameManager.startGame() }
      
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

struct RealmHeaderView: View {
    // MARK: - 参数
    let realmName: String   // 境界名 (如: 胎息)
    let layerName: String   // 层级名 (如: 五层)
    let primaryColor: Color // 主题色
    
    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        // 1. 境界名称 (大标题)
        Text(realmName)
          .font(.system(size: 30, weight: .black, design: .rounded))
          .foregroundColor(.white)
        // 文字发光效果
          .shadow(color: primaryColor.opacity(0.8), radius: 8)
        
        // 2. Lv 胶囊 (徽章)
        Text(layerName)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundColor(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(primaryColor.opacity(0.25)) // 半透明背景
          .clipShape(Capsule())
        // 稍微往上提一点，视觉上与大标题居中对齐
          .offset(y: -4)
      }
      .padding(.top, 20) // 保持原有的顶部间距
    }
}

struct CultivationRingView: View {
    // MARK: - 参数
    let ringSize: CGFloat
    let progress: Double        // 保持 Double
    let primaryColor: Color
    let gradientColors: [Color]
    
    // 常量配置 (全部改为 Double，避免计算时的类型转换麻烦)
    private let trackWidth: CGFloat = 16
    private let startTrim: Double = 0.16
    private let endTrim: Double = 0.84
    
    // 计算有效弧度长度
    private var arcLength: Double { endTrim - startTrim }
    
    var body: some View {
        ZStack {
            // 1. 轨道 (暗色背景)
            Circle()
                // trim 接受 CGFloat，所以这里转一下
                .trim(from: CGFloat(startTrim), to: CGFloat(endTrim))
                .stroke(
                    Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .frame(width: ringSize, height: ringSize)
            
            // 2. 进度光点 (流星头)
            if progress > 0 {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .shadow(color: .white, radius: 4)
                    // 位置：圆的右侧 (3点钟方向)
                    .offset(x: ringSize / 2)
                    // 旋转：90度(到底部) + 360 * (起始位置 + 弧长 * 进度)
                    // ✅ 修复点：这里全都是 Double，不会报错了
                    .rotationEffect(.degrees(90.0 + (360.0 * (startTrim + arcLength * progress))))
            }
            
            // 3. 进度条 (亮色填充)
            Circle()
                // trim 需要 CGFloat
                .trim(from: CGFloat(startTrim), to: CGFloat(startTrim + (arcLength * progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(90),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .shadow(color: primaryColor.opacity(0.6), radius: 8)
                .frame(width: ringSize, height: ringSize)
                .animation(.spring(response: 0.5), value: progress)
        }
    }
}

struct BuffStatusBar: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        HStack(spacing: 8) {
            
            // 1. 点击增益 (Tap Buff)
            if let buff = gameManager.player.tapBuff, Date() < buff.expireAt {
                HStack(spacing: 2) {
                    Image(systemName: "hand.tap.fill")
                    Text("+\(Int(buff.bonusRatio * 100))%")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .clipShape(Capsule())
                .transition(.scale)
            }
            
            // 2. 自动增益 (Auto Buff)
            if let buff = gameManager.player.autoBuff, Date() < buff.expireAt {
                HStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                    Text("+\(Int(buff.bonusRatio * 100))%")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green)
                .clipShape(Capsule())
                .transition(.scale)
            }
            
            // 3. 负面状态 (Debuff)
            if let debuff = gameManager.player.debuff, Date() < debuff.expireAt {
                HStack(spacing: 2) {
                    Image(systemName: "heart.slash.fill")
                    Text("道心不稳")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.8))
                .clipShape(Capsule())
                .transition(.scale)
            }
        }
        // 当状态变化时，添加平滑动画
        .animation(.spring(), value: gameManager.player.tapBuff?.expireAt)
        .animation(.spring(), value: gameManager.player.autoBuff?.expireAt)
    }
}

struct BottomControlView: View {
    @EnvironmentObject var gameManager: GameManager

    @Binding var showBreakthrough: Bool
    let primaryColor: Color // 传入境界颜色
    
    var body: some View {
        Group {
            if gameManager.showBreakButton {
                // --- 模式 A: 突破按钮 ---
                Button(action: {
                    showBreakthrough = true
                }) {
                    Text("立即突破")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6) // 微调高度
                        .background(
                            LinearGradient(
                                colors: [primaryColor, primaryColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: primaryColor.opacity(0.5), radius: 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 5)
                .transition(.opacity) // 切换时的淡入淡出
                
            } else {
                // --- 模式 B: 灵气数值 ---
                let isApproaching = gameManager.getCurrentProgress() >= 0.90
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    // 灵力数值
                    Text(gameManager.player.currentQi.xiuxianString)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(isApproaching ? primaryColor : .white)
                        .contentTransition(.numericText())
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    // 单位
                    Text("灵气")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.bottom, 4)
                }
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        // 整个区域的切换动画
        .animation(.easeInOut(duration: 0.3), value: gameManager.showBreakButton)
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

