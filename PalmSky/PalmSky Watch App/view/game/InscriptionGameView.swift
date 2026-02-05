import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// MARK: - 1. 数据模型：五行符文
enum RuneType: String, CaseIterable, Identifiable {
    case gold = "金"
    case wood = "木"
    case water = "水"
    case fire = "火"
    case earth = "土"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .gold: return .yellow
        case .wood: return .green
        case .water: return .blue
        case .fire: return .red
        case .earth: return .brown
        }
    }
    
    var icon: String {
        switch self {
        case .gold: return "sun.max.fill"
        case .wood: return "leaf.fill"
        case .water: return "drop.fill"
        case .fire: return "flame.fill"
        case .earth: return "mountain.2.fill"
        }
    }
}

// MARK: - 2. 游戏逻辑引擎 (ViewModel)
class InscriptionEngine: ObservableObject {
    @Published var activeRune: RuneType? = nil // 当前亮起的符文
    @Published var statusText: String = "阵法推演" // 中心文字
    @Published var isUserTurn: Bool = false      // 是否允许用户点击
    @Published var errorRune: RuneType? = nil    // 错误符文
    
    // 游戏配置
    private var sequence: [RuneType] = []        // 正确的序列
    private var userIndex: Int = 0               // 用户当前输入到了第几位
    private var currentRound: Int = 1            // 当前轮次
    private let totalRounds = 3                  // 总轮次
    private var baseLength: Int = 3
    private var flashDuration: Double = 0.6
    private var gapDuration: Double = 0.2
    
    var onFinish: ((Bool) -> Void)?
    var onRoundComplete: (() -> Void)?
    
  // 为了更平滑，我们单独用一个 @Published 变量控制显示进度
  @Published var visualProgress: CGFloat = 0.0
  
  
    // 启动游戏
    func startGame(level: Int) {
        visualProgress = 0.0

        applyDifficulty(level: level)
        sequence.removeAll()
        currentRound = 1
        startRound()
    }
    
    // 开始某一轮
    private func startRound() {
        // 1. 生成新序列
        // 难度递增：第1轮3个，第2轮4个，第3轮5个
        let count = baseLength + (currentRound - 1)
        sequence = (0..<count).map { _ in RuneType.allCases.randomElement()! }
        
        userIndex = 0
        isUserTurn = false
        statusText = "观灵光流转"
        
        // 2. 延迟一点开始演示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playDemoSequence()
        }
    }
    
    // 播放演示动画
    private func playDemoSequence() {
        var delay = 0.0
        let flashDuration = flashDuration
        let gapDuration = gapDuration
        
        for (index, rune) in sequence.enumerated() {
            // 亮起
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                HapticManager.shared.play(.click) // 演示时轻微震动
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.activeRune = rune
                }
            }
            
            // 熄灭
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + flashDuration) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.activeRune = nil
                }
            }
            
            delay += (flashDuration + gapDuration)
            
            // 演示结束，移交控制权
            if index == sequence.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isUserTurn = true
                    self.statusText = "循序复刻"
                    HapticManager.shared.play(.directionUp) // 提示用户开始
                }
            }
        }
    }
    
    // 处理用户点击
    func handleInput(_ rune: RuneType) {
        guard isUserTurn else { return }
        
        // 点亮一下反馈
        activeRune = rune
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if self.activeRune == rune { self.activeRune = nil }
        }
        
        // 判定逻辑
        if rune == sequence[userIndex] {
            // ✅ 正确
            HapticManager.shared.play(.click)
            userIndex += 1
            
            if userIndex >= sequence.count {
                // 本轮完成
                roundComplete()
            }
        } else {
            // ❌ 错误
            errorRune = rune
            activeRune = nil
            gameOver(win: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if self.errorRune == rune { self.errorRune = nil }
            }
        }
    }
    
    private func roundComplete() {
        isUserTurn = false
        statusText = "阵纹契合"
        HapticManager.shared.play(.success)
        onRoundComplete?()
        
        // ✨ 本轮完成，阵法进度条涨一截
        let targetProgress: CGFloat
        switch currentRound {
        case 1: targetProgress = 0.2 // 完成第1轮，亮1段
        case 2: targetProgress = 0.6 // 完成第2轮，亮3段 (+2)
        case 3: targetProgress = 1.0 // 完成第3轮，全亮 (+2)
        default: targetProgress = 1.0
        }
        
      // 只有当新进度大于旧进度时才更新 (防止回退变暗)
      if targetProgress > visualProgress {
        withAnimation(.easeInOut(duration: 1.2)) {
          self.visualProgress = targetProgress
        }
      }
      
      
        if currentRound >= totalRounds {
            // 通关
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.onFinish?(true)
            }
        } else {
            // 下一轮
            currentRound += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startRound()
            }
        }
    }
    
    private func gameOver(win: Bool) {
        isUserTurn = false
        statusText = win ? "渡劫成功" : "阵法崩塌"
        HapticManager.shared.play(win ? .success : .failure)
        
        // 视觉反馈：红色闪烁
        if !win {
            withAnimation { self.activeRune = nil } // 清除高亮
        }
        
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.onFinish?(win)
        }
    }
    
    private func applyDifficulty(level: Int) {
        let stageIndex = (level - 1) / 9
        let localStage = max(0, min(3, stageIndex - 8))
        baseLength = min(5, 3 + localStage)
        
        print("level", level, baseLength)
        flashDuration = max(0.35, 0.6 - Double(localStage) * 0.08)
        gapDuration = max(0.12, 0.2 - Double(localStage) * 0.03)
        
        if baseLength >= 5 {
            flashDuration = max(flashDuration, 0.45)
            gapDuration = max(gapDuration, 0.16)
        }
    }
}

// MARK: - 3. 主视图 (UI Layout)
struct InscriptionGameView: View {
    let level: Int
    let startWhenReady: Bool
    let onFinish: (Bool) -> Void
    
    @StateObject private var engine = InscriptionEngine()
    @State private var hasStarted = false
    @State private var runeAppeared: [Bool] = Array(repeating: false, count: RuneType.allCases.count)
    @State private var runePulse: [Bool] = Array(repeating: false, count: RuneType.allCases.count)
    @State private var ringRotation: Double = 0
    @State private var runeOrder: [RuneType] = RuneType.allCases
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let centerY = size.height / 2
            let center = CGPoint(x: size.width / 2, y: centerY)
            // 半径：屏幕宽度的一半，减去符文半径(30)和边距
            let radius = min(size.width, size.height) * 0.38
              
          // let width = geo.size.width

            #if os(watchOS)
            let width = geo.size.width
            #elseif os(iOS)
            let width = geo.size.width - 15
            #endif
                      
            let colors = RealmColor.gradient(for: level)
            let primaryColor = colors.last ?? .green
          
            ZStack {
                // 1. 背景
                Color.black.ignoresSafeArea()
                
            
                // 底部氛围光 (让底部数据不那么单调)
                RadialGradient(
                    gradient: Gradient(colors: [primaryColor.opacity(0.2), .clear]),
                    center: UnitPoint(x: 0.5, y: 0.5), // 光源在底部
                    startRadius: 20,
                    endRadius: width
                )
                .ignoresSafeArea()
                
              // Layer A: 底轨 (暗虚线)
              StarPath(center: center, radius: radius)
                .stroke(
                  Color.white.opacity(0.15), // 暗灰
                  style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
                )
              
              
              // Layer B: 进度 (亮实线/光晕)
              // 只有当进度 > 0 才显示
              if engine.visualProgress > 0 {
                StarPath(center: center, radius: radius)
                  .trim(from: 0, to: engine.visualProgress) // 从头开始画
                  .stroke(
                    // 使用流光金，但不要透明度渐变，要实打实的亮色
                    LinearGradient(
                      colors: [.orange, .yellow, .white],
                      startPoint: .leading,
                      endPoint: .trailing
                    ),
                    // 🔥 关键：使用实线 (不加 dash)，线条加粗
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
                  )
                // 强力发光，这就是"激活"的感觉
                  .shadow(color: .orange, radius: 10)
                  .shadow(color: .yellow, radius: 2)
                // 动画平滑过渡
                  .animation(.easeInOut(duration: 1.0), value: engine.visualProgress)
              }
              
                // 阵法底图 (装饰)
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                
                // 2. 五行符文 (圆周排列)
                ForEach(Array(runeOrder.enumerated()), id: \.element) { index, rune in
                    // 计算角度：从 -90度 (12点钟) 开始，顺时针排列
                    // 360 / 5 = 72度
                    let angle = Angle.degrees(Double(index) * 72.0 - 90.0)
                    
                    // 极坐标转直角坐标
                    let x = center.x + radius * CGFloat(cos(angle.radians))
                    let y = center.y + radius * CGFloat(sin(angle.radians))
                    
                    RuneButton(
                        type: rune,
                        isActive: engine.activeRune == rune,
                        introPulse: runePulse[index],
                        isError: engine.errorRune == rune
                    ) {
                        engine.handleInput(rune)
                    }
                    .scaleEffect(runeAppeared[index] ? 1.0 : 0.2)
                    .opacity(runeAppeared[index] ? 1.0 : 0.0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(index) * 0.06), value: runeAppeared[index])
                    .position(x: x, y: y)
                    .shadow(color: rune.color.opacity(0.45), radius: 6, x: 0, y: 0)
                }
                .rotationEffect(.degrees(ringRotation))
                
                
                // 3. 中心状态文字
                VStack(spacing: 4) {
                    Text(engine.statusText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(engine.isUserTurn ? .white : .gray)
                        .transition(.opacity)
                        .id("status_\(engine.statusText)") // 强制刷新动画
                    
                }
            }
       
        }
        #if os(watchOS)
//        .offset(y: 20)
        .ignoresSafeArea()
        #endif
        .onAppear {
            engine.onFinish = onFinish
            engine.onRoundComplete = { rotateRuneRing() }
            if startWhenReady && !hasStarted {
                hasStarted = true
                engine.startGame(level: level)
            }
            triggerRuneIntro()
        }
        .onChange(of: startWhenReady) { _, ready in
            if ready && !hasStarted {
                hasStarted = true
                engine.startGame(level: level)
            }
        }
    }
    
    private func triggerRuneIntro() {
        for i in runeAppeared.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                runeAppeared[i] = true
                runePulse[i] = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    runePulse[i] = false
                }
            }
        }
    }
  
    
    private func rotateRuneRing() {
        withAnimation(.easeInOut(duration: 0.6)) {
            ringRotation += 72
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ringRotation = 0
            runeOrder = runeOrder.shuffled()
        }
    }
}

struct RuneButton: View {
    let type: RuneType
    let isActive: Bool
    let introPulse: Bool
    let isError: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 入场灵气环
                Circle()
                    .trim(from: 0.05, to: 0.75)
                    .stroke(type.color.opacity(introPulse ? 0.9 : 0.0), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .rotationEffect(introPulse ? .degrees(300) : .degrees(0))
                    .scaleEffect(introPulse ? 1.2 : 0.6)
                    .opacity(introPulse ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6), value: introPulse)
                
                // 1. 光晕 (激活时爆发，未激活时微弱呼吸)
                if isActive {
                    Circle()
                        .fill(type.color)
                        .frame(width: 50, height: 50)
                        .blur(radius: 10) // 大光晕
                        .opacity(0.8)
                } else {
                    // 未激活时，也有一点点微弱的颜色，不至于死黑
                    Circle()
                        .strokeBorder(type.color.opacity(0.5), lineWidth: 1)
                        .frame(width: 46, height: 46)
                }
                
                // 2. 底座
                Circle()
                    .fill(isError ? Color.red.opacity(0.25) : (isActive ? type.color.opacity(0.2) : Color(white: 0.1, opacity: 0.8)))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isError ? Color.red : (isActive ? Color.white : type.color.opacity(0.3)), lineWidth: isActive ? 2 : 5)
                    )
                
                // 3. 汉字 (关键修改：使用 Serif 衬线体)
                Text(type.rawValue)
                    // 🔥 system(size: 22, design: .serif) -> 宋体风格
                    .font(.system(size: 22, weight: isActive ? .black : .bold, design: .serif))
                    .foregroundColor(isError ? .red : (isActive ? .white : type.color.opacity(0.6))) // 平时带点颜色
                    .shadow(color: isError ? .red : (isActive ? type.color : .clear), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.15 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

struct StarPath: Shape {
    let center: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 五角星连线顺序：0 -> 2 -> 4 -> 1 -> 3 -> 0
        // 这样 trim 动画才会顺着星星的笔画走
        let order = [0, 2, 4, 1, 3, 0]
        
        for (i, index) in order.enumerated() {
            let angle = Angle.degrees(Double(index) * 72.0 - 90.0)
            let x = center.x + radius * CGFloat(cos(angle.radians))
            let y = center.y + radius * CGFloat(sin(angle.radians))
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

// 预览
struct InscriptionGameView_Previews: PreviewProvider {
    static var previews: some View {
        InscriptionGameView(level: 90, startWhenReady: true) { win in
            print("Game Over: \(win)")
        }
        .frame(width: 190, height: 230) // 模拟 45mm
    }
}
