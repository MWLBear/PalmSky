
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
                
                // 4. 信息层 (Text Overlay)
                VStack {
              
                    ZStack {
                      // 这一层产生强烈的彩色光晕背景
                      Text(gameManager.getRealmShort())
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(primaryColor) // 境界色
                        .blur(radius:6) // 模糊化，变成光晕
                        .opacity(0.6)
                      
                      // 这一层是清晰的白色文字
                      Text(gameManager.getRealmShort())
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white) // 纯白，保证清晰
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    }
                    .padding(.top)
                  
            
                    Spacer()
                    
                    // --- 底部：数据聚合 ---
                    // 放在圆环缺口处
                    VStack(spacing: 2) {
                        if gameManager.showBreakButton {
                            // 突破模式：闪烁按钮
                          Button(action: {
                            showBreakthrough = true
                          }) {
                                Text("立即突破")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                      LinearGradient(colors: [primaryColor, primaryColor.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .orange.opacity(0.6), radius: 8)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 10)
                        } else {
                            // 正常模式：数值 + 等级
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                // 灵力数值 (超大)
                                Text("\(Int(gameManager.player.currentQi))")
                                    .font(.system(size: 26, weight: .bold, design: .rounded)) // 特大号数字
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1) // 描边阴影

                                // 单位
                                Text("灵气")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.8)) // 半透明白
                                    .padding(.bottom, 6)
                            }

                            // 等级胶囊 (高亮显示，解决看不清的问题)
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill") // 小图标增加精致感
                                    .font(.system(size: 8))
                                Text("Lv.\(gameManager.player.level % 9 == 0 ? 9 : gameManager.player.level % 9)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                              Capsule()
                                .fill(Color.white.opacity(0.15)) // 磨砂玻璃感背景
                                .overlay(
                                  Capsule().stroke(primaryColor.opacity(0.3), lineWidth: 1) // 细边框
                                )
                            )
                            .padding(.bottom, 10) // 离底部边缘的距离
                        }
                    }
                }
                .ignoresSafeArea() // 这一步很关键，允许文字推到最边缘
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear { gameManager.startGame() }
        .onLongPressGesture { showSettings = true }
        .sheet(isPresented: $showBreakthrough) { BreakthroughView(isPresented: $showBreakthrough) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $gameManager.showEventView) {
            if let event = gameManager.currentEvent { EventView(event: event) }
        }
    }
}



struct QiRippleEffect: View {
    let color: Color
    
    // 动画状态由外部控制，这里只负责画图
    // 但为了让每个粒子有独立生命周期，我们这里用 TimelineView 或者简单的 View
    // 鉴于之前是在 TaijiView 里用数组管理的，我们这里只定义"样子"
    
    var body: some View {
        ZStack {
            // Layer 1: 核心能量爆发 (中心亮，边缘透明)
            // 模拟灵气炸开的冲击波
            RadialGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.6), // 中心高亮
                    color.opacity(0.1), // 中间淡
                    .clear              // 边缘透明
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 50 // 这个半径会被 scaleEffect 放大
            )
            .blur(radius: 5) // 模糊处理，让它看起来像气体而不是几何图形
            
            // Layer 2: 灵气湍流 (旋转的虚线环)
            // 模拟灵力激荡产生的气旋
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.0)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 20])
                )
                // 注意：这里我们不加旋转动画，因为旋转会由 TaijiView 的 updatePhysics 统一驱动
                // 或者我们可以利用 scale 的变化产生视觉错觉
        }
    }
}



struct TaijiView: View {
    // MARK: - External Props
    let level: Int
    let onTap: () -> Void
    
    // MARK: - Physics State
    @State private var rotation: Double = 0
    @State private var extraVelocity: Double = 0 // 额外的冲量速度
    @State private var scale: CGFloat = 1.0
    @State private var lastTime: Date = Date()
    
    // MARK: - Visual State
    @State private var waves: [QiWave] = []
    struct QiWave: Identifiable {
        let id = UUID()
        var scale: CGFloat = 0.5
        var opacity: Double = 1.0
    }
    
    // MARK: - Constants & Config
    // 基础速度公式: 30度/秒 + (大境界 * 5度)
    // 境界越高，基础自转越快，显得修为深厚
    private var baseVelocity: Double {
        let stage = Double((level - 1) / 9)
        return 30.0 + (stage * 5.0)
    }
    
    // 最大速度限制 (度/秒) - 约每秒 3 圈
    private let maxVelocity: Double = 1080.0
    
    // 每次点击增加的冲量 (度/秒)
    private let tapImpulse: Double = 200.0
    
    // 衰减系数 (0.0 - 1.0)，越小衰减越快。
    // 这里用时间指数衰减模拟阻尼
    private let decayFactor: Double = 2.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date
            
            ZStack {
                // 1. 境界光晕 (呼吸 + 随速度变亮)
                // 速度越快，光晕越强，模拟"灵力鼓动"
                let colors = RealmColor.gradient(for: level)
                let energyRatio = min(extraVelocity / 800.0, 1.0) // 0~1 based on speed
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colors[1].opacity(0.3 + energyRatio * 0.4), // 速度快时更亮
                                colors[0].opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 45,
                            endRadius: 90 + (energyRatio * 20) // 速度快时光圈变大
                        )
                    )
                    .scaleEffect(1.0 + sin(now.timeIntervalSince1970 * 2) * 0.05)
                
                // 2. 气波扩散 (点击反馈)
                ForEach(waves) { wave in
                    Circle()
                        .stroke(colors.last ?? .white, lineWidth: 2)
                        .scaleEffect(wave.scale)
                        .opacity(wave.opacity)
                }
                
                // 3. 太极主体
                Image("TaiChi") // 务必在 Assets 中放入透明背景的太极图
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    // 速度越快，阴影越深，浮空感越强
                    .shadow(
                        color: colors[0].opacity(0.5 + energyRatio * 0.5),
                        radius: 10 + (energyRatio * 10),
                        x: 0,
                        y: 0
                    )
            }
            .contentShape(Circle()) // 扩大点击热区
            .onTapGesture {
                handleTap()
            }
            .onChange(of: now) { newDate in
                updatePhysics(currentTime: newDate)
            }
        }
    }
    
    // MARK: - 核心物理逻辑
    private func updatePhysics(currentTime: Date) {
        let deltaTime = currentTime.timeIntervalSince(lastTime)
        lastTime = currentTime
        
        // 1. 计算当前总速度 (基础 + 额外)
        let currentVelocity = baseVelocity + extraVelocity
        
        // 2. 更新角度
        rotation += currentVelocity * deltaTime
        
        // 3. 物理衰减 (阻尼)
        // 只有 extraVelocity 需要衰减，baseVelocity 是恒定的
        if extraVelocity > 0 {
            // 使用指数衰减公式，保证帧率无关性
            // 每一秒减少 velocity = velocity - (velocity * decay * dt)
            extraVelocity -= extraVelocity * decayFactor * deltaTime
            
            // 阈值归零
            if extraVelocity < 1.0 { extraVelocity = 0 }
        }
        
        // 4. 更新波纹动画
        for i in waves.indices.reversed() {
            waves[i].scale += 3.0 * deltaTime
            waves[i].opacity -= 2.0 * deltaTime
            if waves[i].opacity <= 0 {
                waves.remove(at: i)
            }
        }
        
        // 5. 缩放回弹 (点击时的Q弹感)
        if scale > 1.0 {
            scale -= 2.0 * deltaTime
            if scale < 1.0 { scale = 1.0 }
        }
    }
    
    private func handleTap() {
        // 1. 增加冲量 (限制最大速度)
        if (baseVelocity + extraVelocity + tapImpulse) < maxVelocity {
            extraVelocity += tapImpulse
        }
        
        // 2. 视觉反馈
        scale = 1.15 // 瞬间变大
        waves.append(QiWave()) // 产生气波
        
        // 3. 业务回调
        onTap()
    }
}
