import SwiftUI

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
    // ✨ 外部物理冲量触发器 (UUID变化时触发)
    var triggerImpulse: UUID?
    let onTap: () -> Void
    
    // 监听皮肤变化
     @ObservedObject var skinManager = SkinManager.shared
  
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
            
      GeometryReader { geo in
        let size = min(geo.size.width, geo.size.height)
        // 🔴 核心：太极实体的直径，只占容器的 68% (留出 32% 给光晕)
        let shapeSize = size * 0.68
        
        // ⚡ 性能优化：从 60fps 降至 15fps，在视觉流畅和功耗之间取得平衡
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
                  startRadius: shapeSize * 0.35,
                  endRadius: size * 0.6 + (energyRatio * 40)
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
//                            Image("TaiChi")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 125, height: 125)
//                                .rotationEffect(.degrees(rotation))
//                                .scaleEffect(scale)
//                                .shadow(
//                                    color: primaryColor.opacity(0.5 + energyRatio * 0.5),
//                                    radius: 10 + (energyRatio * 15)
//                                )
            
            TaijiShapeView(skin: skinManager.currentSkin)
              .frame(width: shapeSize, height: shapeSize)
              .rotationEffect(.degrees(rotation))
              .scaleEffect(scale)
//              .shadow(
//                color: primaryColor.opacity(0.4 + energyRatio * 0.4),
//                radius: 12 + (energyRatio * 10),
//                x: 0, y: 0
//              )
            
            // 阴影：增加扩散，减少不透明度，增加悬浮感
              .shadow(
                color: primaryColor.opacity(0.5),
                radius: 15,
                x: 0, y: 0
              )
          }
          .contentShape(Circle())
          .onTapGesture { handleTap() }
          .onChange(of: now) {oldDate, newDate in updatePhysics(currentTime: newDate) }
          // ✨ 响应外部冲量 (炼化步数时)
          .onChange(of: triggerImpulse) { _, _ in
              // 猛烈旋转 + 爆发波纹
              extraVelocity += 800
              scale = 1.25 // 很大幅度的缩放
              // 连发3道波纹
              for i in 0..<3 {
                  var wave = QiWave()
                  wave.scale = 0.2 + CGFloat(i) * 0.1
                  wave.rotationSpeed = 300
                  waves.append(wave)
              }
          }
        }
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
