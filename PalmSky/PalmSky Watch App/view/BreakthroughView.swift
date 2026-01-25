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
  
    // ✨✨✨ 新增：小游戏状态 ✨✨✨
    @State private var showMiniGame = false
    @State private var miniGameType: GameLevelManager.TribulationGameType = .none
  
    #if os(watchOS)
    let visualOffsetY: CGFloat = 15.0
    #elseif os(iOS)
    let visualOffsetY: CGFloat = 0.0
    #endif
    // Bottom padding needs to be consistent
 
    #if os(watchOS)
    let bottomPadding: CGFloat = 15.0
    #elseif os(iOS)
    let bottomPadding: CGFloat = 15.0
    #endif
  
    enum BreakthroughResult {
        case success
        case failure
    }
    
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
          
            #if os(watchOS)
            let width = geo.size.width
            #elseif os(iOS)
            let width = geo.size.width - 15
            #endif
                      
            let height = geo.size.height

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
                  ZStack {
                    
                    // 视觉核心
                    BreakthroughVisualsView(
                      width: width,
                      primaryColor: primaryColor,
                      colors: colors,
                      isAttempting: isAttempting,
                      particles: particles,
                      coreRotation: coreRotation,
                      coreBrightness: coreBrightness,
                      coreScale: coreScale,
                      shockwaveScale: shockwaveScale,
                      shockwaveOpacity: shockwaveOpacity,
                      // ✨ 传入成功率
                      successRate: GameLevelManager.shared.breakSuccess(level: gameManager.player.level)
                    )
                    .offset(y: visualOffsetY)
                    
                    VStack {
                      Spacer() // 这是一个强力弹簧，把下面的内容死死压在底部
                      
                      BreakthroughControlsView(
                        primaryColor: primaryColor,
                        isAttempting: isAttempting,
                        action: startBreakthrough
                      )
                      // 🚀 核心修改：这里控制距离底部的距离
                      .padding(.bottom, bottomPadding)
                    }
                    // 确保 Layer B 能利用到底部安全区空间
                    .ignoresSafeArea(edges: .bottom)
                    
                    // ✨✨✨ C. 小游戏层 (覆盖在最上面) ✨✨✨
                    if showMiniGame {
                      MiniGameContainer(
                        type: miniGameType,
                        level: gameManager.player.level,
                        isPresented: $isPresented
                      ) { isWin in
                        // 游戏结束回调
                        handleMiniGameFinish(isWin: isWin)
                      }
                      .transition(.opacity.animation(.easeInOut))
                      .zIndex(100) // 确保在最顶层
                    }
              
  
                  }
                    
                } else {
    
                  // 结果页
                  BreakthroughResultView(
                    result: result,
                    primaryColor: primaryColor,
                    height: height,
                    showResultView: showResultView,
                    isPresented: $isPresented,
                    onAutoContinue: handleAutoContinue // ✨ 绑定自动逻辑
                  )
                  .ignoresSafeArea()
                }
                
                // 闪光层
                Color.white.ignoresSafeArea().opacity(flashOpacity).allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                updateParticles()
            }
        }
    }
    
    // MARK: - ✨ 粒子与动画逻辑
    private func startBreakthrough() {
      
       HapticManager.shared.playIfEnabled(.click)

      // 判断当前等级是否需要玩游戏
        let type = GameLevelManager.shared.getTribulationGameType(for: gameManager.player.level)
        
        if type == .none {
          // A. 普通层级：走原来的纯概率动画
          runNormalAnimation()
        } else {
          // B. 大境界突破：启动小游戏
          startMiniGame(type: type)
        }
        
    }
    
  // 2. 启动小游戏
    private func startMiniGame(type: GameLevelManager.TribulationGameType) {
        withAnimation { isAttempting = true }
        // 稍微延迟一点弹出游戏，给一点 UI 响应时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.miniGameType = type
            withAnimation(.spring()) {
                self.showMiniGame = true
            }
        }
    }
  
    // 3. 小游戏结束回调
    private func handleMiniGameFinish(isWin: Bool) {
      // 关闭游戏界面
      withAnimation { showMiniGame = false }
      
      // 调用 GameManager 进行结算 (软惩罚/奖励逻辑)
      let success = gameManager.finalizeMiniGame(isWin: isWin)
      
      // 播放结算动画 (闪光 + 结果页)
      playResultAnimation(success: success)
      
    }
    
    // 4. 原来的动画流程 (抽离出来)
     private func runNormalAnimation() {
       
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
             
             let success = gameManager.attemptBreak()
             //🔥 调用通用结算动画
             playResultAnimation(success: success)
           
         }
     }
  
  
   // 5. 统一的结果展示动画
    private func playResultAnimation(success: Bool) {
      // 1. 白光一闪
        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 1.0 }
        
        // 2. 震动反馈
        HapticManager.shared.playIfEnabled(success ? .success : .failure)
        
        // 3. 设置结果数据
        result = success ? .success : .failure
        
        // 4. 切换到结果视图
        withAnimation {
          showResultView = true
          // 如果不需要看动画倒放，可以在这里重置 isAttempting
          // isAttempting = false
        }
        
        // 5. 白光消退
        withAnimation(.easeOut(duration: 1.0).delay(0.1)) { flashOpacity = 0.0 }
    }
    
    // ✨ 自动连招逻辑
    private func handleAutoContinue() {
        // 重置 UI 状态
        withAnimation(.easeOut(duration: 0.3)) {
            showResultView = false
            flashOpacity = 0.0
            isAttempting = false
            result = nil
            // 重置动画相关的
            coreScale = 1.0
            coreBrightness = 0.0
            shockwaveOpacity = 0.0
        }
        
        print("🔄 自动连击：发起下一轮冲击...")
        // 立即触发下一次
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startBreakthrough()
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

struct BreakthroughVisualsView: View {
    @EnvironmentObject var gameManager: GameManager
    let width: CGFloat
    let primaryColor: Color
    let colors: [Color]
    
    // 动画状态
    let isAttempting: Bool
    let particles: [QiParticle]
    let coreRotation: Double
    let coreBrightness: Double
    let coreScale: CGFloat
    let shockwaveScale: CGFloat
    let shockwaveOpacity: Double

    #if os(watchOS)
    let sacleWidth = 0.85
    #elseif os(iOS)
    let sacleWidth = 1.0
    #endif
  
    #if os(watchOS)
    let lineWidth = 10.0
    #elseif os(iOS)
    let lineWidth = 16.0
    #endif
  
    // ✨ 新增：接收成功率用于显示
    let successRate: Double
    
    let offsetY = -15.0

    var body: some View {
        ZStack {
            // A. 静态底轨
            Circle()
                .trim(from: 0.16, to: 0.84)
                .stroke(primaryColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))
                .frame(width: width * sacleWidth, height: width * sacleWidth)
            
            // B. 境界文字 (上半部分)
            if !isAttempting {
                VStack(spacing: 5) {
                    Text(gameManager.getRealmShort())
                        .font(XiuxianFont.realmTitle)
                        .foregroundColor(.white)
                        .shadow(color: primaryColor, radius: 10)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .layoutPriority(1)
                    
                    Text(gameManager.getLayerName())
                        .font(XiuxianFont.badge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(primaryColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                .transition(.opacity)
                .offset(y: offsetY) // 稍微往上提一点，避开圆心
            }
                      
          // C. 底部信息位 (共鸣率 / 状态提示)
            Text(isAttempting ? "天地灵气汇聚中..." : "共鸣率 \(Int(successRate * 100))%")
              .font(XiuxianFont.body)
            // 颜色切换：平时灰色，突破时亮色
              .foregroundColor(isAttempting ? primaryColor : .gray)
            // 位置固定
              .offset(y: calculateGapYOffset(width: width,scale: sacleWidth))
              .id(isAttempting ? "status" : "rate")
              .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            
            // D. 灵气粒子
            ForEach(particles) { p in
                Circle()
                    .fill(primaryColor)
                    .frame(width: p.size, height: p.size)
                    .opacity(p.opacity)
                    .offset(x: cos(p.angle) * p.distance, y: sin(p.angle) * p.distance)
            }
            
            // E. 核心丹田
            if isAttempting {
                ZStack {
                    Circle()
                        .fill(AngularGradient(colors: [primaryColor.opacity(0), primaryColor], center: .center))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(coreRotation))
                        .blur(radius: 5)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: primaryColor, radius: 10 + coreBrightness * 20)
                        .scaleEffect(coreScale)
                }.offset(y: offsetY) // 稍微往上提一点，避开圆心
            }
            
            // F. 冲击波
            Circle()
                .stroke(Color.white, lineWidth: 20)
                .frame(width: 50, height: 50)
                .scaleEffect(shockwaveScale)
                .opacity(shockwaveOpacity)
        }
        .frame(width: width, height: width)
    }
  
  
  /// 计算圆环缺口连线的垂直偏移量 (从圆心向下)
      /// - Returns: Y轴偏移量
      func calculateGapYOffset(width: CGFloat, scale: CGFloat = 0.85, startTrim: Double = 0.16, endTrim: Double = 0.84) -> CGFloat {
          // 1. 半径
          let radius = (width * scale) / 2
          
          // 2. 计算缺口的一半角度 (弧度制)
          // 缺口比例 = 1.0 - (0.84 - 0.16) = 0.32
          let gapRatio = 1.0 - (endTrim - startTrim)
          // 360度 * 缺口比例 / 2 = 半角
          // 转换成弧度: 2 * pi * ratio / 2 = pi * ratio
          let halfGapAngleRadians = gapRatio * .pi
          
          // 3. 计算垂直距离 (余弦定理)
          // 这就是从圆心向下到"缺口连线"的精确距离
          let chordDistance = radius * cos(halfGapAngleRadians)
                    
          #if os(watchOS)
          return chordDistance
          #elseif os(iOS)
          return chordDistance - 15
          #endif
        
      }
  
}


struct BreakthroughControlsView: View {
    @EnvironmentObject var gameManager: GameManager
    let primaryColor: Color
    let isAttempting: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {

            Spacer().frame(height: 10)

          
            BottomActionButton(
                title: isAttempting ? "突破中..." : (gameManager.player.settings.autoBreakthrough ? "自动冲关" : "逆天改命"),
                primaryColor: primaryColor
            ) {
                action()
            }
            .disabled(isAttempting)
            .overlay(
                Group {
                    if isAttempting {
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                }
            )
        }
    }
}


struct BreakthroughResultView: View {
    let result: BreakthroughView.BreakthroughResult?
    let primaryColor: Color
    let height: CGFloat
    let showResultView: Bool
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    // ✨ 回调：自动继续
    var onAutoContinue: () -> Void
    
    // 倒计时状态
    @State private var autoCountdown = 1.5
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            VStack(spacing: 5) {
                Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: height * 0.25))
                    .foregroundColor(result == .success ? primaryColor : Color.orange.opacity(0.8))
                    .symbolEffect(.bounce, value: showResultView)
                
                Text(result == .success ? "突破成功" : "突破失败")
                    .font(XiuxianFont.realmResultTitle)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                
                if result == .success {
                    Text(gameManager.getCurrentRealm())
                        .font(XiuxianFont.realmSubtitle)
                        .foregroundColor(primaryColor)
                } else {
                    Text("道心受损 -\(gameManager.currentPenaltyPercentage)%")
                        .font(XiuxianFont.body)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 25)
            
            Spacer()
            
            // 按钮区域
            if shouldAutoContinue() {
                 VStack(spacing: 4) {
                    ProgressView()
                        .tint(primaryColor)
                    Text("闭关冲击中 \(String(format: "%.1f", autoCountdown))s")
                        .font(XiuxianFont.body)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
                .onAppear { startAutoTimer() }
                .onDisappear { stopTimer() }
                
            } else {
                BottomActionButton(
                    title: "完成",
                    primaryColor: primaryColor
                ) {
                    closeView()
                }
                .padding(.bottom, 15)
            }
        }
    }
    
    // 逻辑：判断是否处于自动连招状态
    func shouldAutoContinue() -> Bool {
        // 1. 结果必须是成功
        guard result == .success else { return false }
        // 2. 开关必须开启
        guard gameManager.player.settings.autoBreakthrough else { return false }
        // 3. 必须还能继续 (有灵气，非瓶颈)
        guard gameManager.canAutoBreakNext() else { return false }
        
        return true
    }
    
    // 启动倒计时
    private func startAutoTimer() {
        autoCountdown = 1.5
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            autoCountdown -= 0.1
            if autoCountdown <= 0 {
                stopTimer()
                onAutoContinue()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func closeView() {
        isPresented = false
        if result == .success {
            gameManager.checkFeiSheng()
        }
    }
}
