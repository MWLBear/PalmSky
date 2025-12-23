import SwiftUI

struct RootPagerView: View {
    @EnvironmentObject var gameManager: GameManager

    @State private var page = 0
    @State private var showBreakthrough = false
    @State private var showCelebration = false
    @State private var showReview = false
    @ObservedObject var recordManager = RecordManager.shared

    @Environment(\.scenePhase) var scenePhase

  
    // 提取跳转逻辑，避免重复代码
    private func proceedToReview() {
        // 防止重复触发
        guard showCelebration else { return }
        
        withAnimation(.easeIn(duration: 0.5)) {
            showCelebration = false
            showReview = true
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $page) {
                MainView(showBreakthrough: $showBreakthrough).tag(0)
                SettingsView(currentTab: $page).tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .sheet(isPresented: $showBreakthrough) {
              NavigationView {
                BreakthroughView(isPresented: $showBreakthrough)
              }
              .toolbar(.hidden, for: .navigationBar)

            }
            .sheet(isPresented: $gameManager.showEventView) {
                if let event = gameManager.currentEvent {
                  NavigationView {
                    EventView(event: event)
                  }
                  .toolbar(.hidden, for: .navigationBar)
                }
            }

            // 庆祝界面 (ZIndex 2)
            if showCelebration {
                CelebrationView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 100)),
                        removal: .opacity // 消失时淡出即可，不要乱飞
                    ))
                    .zIndex(2)
                    // 🔥 优化1：允许玩家点击屏幕立即进入下一步
                    .onTapGesture {
                        proceedToReview()
                    }
            }

            // 回顾界面 (ZIndex 1)
            // 注意：showReview 出现时，Celebration 消失，所以 ZIndex 没冲突
            if showReview {
                LifeReviewView {
                    // 关闭回顾的逻辑：回到主页观想模式
                    withAnimation {
                        showReview = false
                        // 确保庆祝也没了
                        showCelebration = false
                        // 确保 GameManager 状态正确 (它应该已经是满级状态了)
                    }
                }
                .transition(.opacity)
                .zIndex(3) // 设高一点，盖住一切
            }
        }
        // body 底部添加
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("☀️ Active: 回到前台")
                // ⚡ 修复：标记 App 为活跃状态
                gameManager.isAppActive = true
              
                // 1. 回到前台，取消之前的通知 (因为我已经上线了，不用再提醒我了)
                NotificationManager.shared.cancelNotifications()
              
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    gameManager.calculateOfflineGain()
                }
            } else if newPhase == .background {
                // App 切后台，保存时间
                print("🌙 Background: 彻底闭关")
                // ⚡ 修复：标记 App 为非活跃状态
                gameManager.isAppActive = false
              
                gameManager.player.lastLogout = Date() // 更新时间
                gameManager.savePlayer()
              
              // 2. ✨ 切后台，埋下一颗 12小时后的"闹钟"
              // 只有未满级才需要提醒
              if gameManager.player.level < GameConstants.MAX_LEVEL {
                NotificationManager.shared.scheduleFullGainNotification()
              }
              
            } else if newPhase == .inactive {
                // ⚡ 修复：inactive 状态也标记为非活跃（息屏）
                print("💤 Inactive: 息屏")
                gameManager.isAppActive = false
            }
//            else if newPhase == .inactive {
//                print("💤 Inactive: 视为暂停/准备离线")
//                
//                gameManager.player.lastLogout = Date()
//                gameManager.savePlayer()
//            }
          
        }
      
        // 监听满级标记
        .onChange(of: gameManager.showEndgame) {oldValue, newValue in
            if newValue {
                // 1. 显示庆祝
                withAnimation(.spring()) {
                    showCelebration = true
                }

                // 2. 🔥 优化2：缩短自动跳转时间 (3.0s -> 2.0s)
                // 2秒足够看清"飞升成功"四个大字了
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    // 只有当还在显示庆祝时才自动跳转
                    // (如果玩家已经手动点了，这里就不执行)
                    if showCelebration {
                        proceedToReview()
                    }
                }
            }
        }
    }
}


struct MainView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var showBreakthrough: Bool
    // 动画状态
    @State private var pulse = false
    
   //✨ 新增：专门控制圆环闭合的视觉状态
    @State private var visualIsAscended = false
  
    let offsetY = 15.0
  
    var body: some View {
        GeometryReader { geo in
            // 核心尺寸计算
            let screenWidth = geo.size.width
            let ringSize = screenWidth * 0.90 // 圆环撑满 90% 屏幕
            let taijiSize = screenWidth * 0.65 // 太极占 65%
            
            let colors = RealmColor.gradient(for: gameManager.player.level)
            let primaryColor = colors.last ?? .green
            
            ZStack {
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
                  gradientColors: [colors.first ?? primaryColor, primaryColor],
                  isAscended: visualIsAscended
                )
                .offset(y: visualIsAscended ? 0 : offsetY)
           
                // 3. 物理太极 (居中)
                TaijiView(level: gameManager.player.level, onTap: {
                  if !gameManager.isAscended {
                      gameManager.onTap()
                    } else {
                      // 满级仅播放震动和动画
                      HapticManager.shared.playIfEnabled(.click)

                    }
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
                .offset(y: visualIsAscended ? 0 : offsetY)

                // 4. 信息层 (Text Overlay)
                VStack {
                  
                  if gameManager.isAscended {
                     EmptyView()
                  } else {
                    
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
                }
                .ignoresSafeArea() // 这一步很关键，允许文字推到最边缘
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toast(message: $gameManager.offlineToastMessage)

        .onAppear { gameManager.startGame() }
      
   
      
        .onChange(of: showBreakthrough) {oldShowing, isShowing in
          
          if !isShowing {
            if gameManager.isAscended {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 3.0)) {
                  visualIsAscended = true
                }
              }
            }
          }
        }
        // ✨ 修复转世重修后圆环不打开的 Bug
        .onChange(of: gameManager.player.level) { oldLevel, newLevel in
          // 如果等级变回了非满级 (即转世了)，且当前视觉上还是闭合的
          if newLevel < GameConstants.MAX_LEVEL && visualIsAscended {
            // 播放一个“圆环重新开启”的动画，象征新轮回开始
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
              visualIsAscended = false
            }
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
        // ⚡ 性能优化：从 60fps 降至 10fps，减少 CPU 唤醒 .periodic(from: .now, by: 0.1)
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: 4 * particle.scale, height: 4 * particle.scale)
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .onChange(of: timeline.date) { _, _ in updateParticles() }
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
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        // 1. 境界名称 (大标题)
        Text(realmName)
          .font(XiuxianFont.realmTitle)
          .foregroundColor(.white)
        // 文字发光效果
          .shadow(color: primaryColor.opacity(0.8), radius: 8)
        // ⬇️ 修改2：核心适配逻辑
          .lineLimit(1)            // 强制不换行
          .minimumScaleFactor(0.5) // 空间不够时，允许缩小到 13pt
          .layoutPriority(1)       // 如果空间挤，优先压缩这个 Text
        
        // 2. Lv 胶囊 (徽章)
        Text(layerName)
          .font(XiuxianFont.badge)
          .foregroundColor(.white)
          .padding(.horizontal, 5)
          .padding(.vertical, 2)
          .background(primaryColor.opacity(0.25)) // 半透明背景
          .clipShape(Capsule())
        // 稍微往上提一点，视觉上与大标题居中对齐
          .offset(y: -2)
      }
      .padding(.top, 20) // 保持原有的顶部间距
    }
}

struct CultivationRingView: View {
    // MARK: - 参数
    let ringSize: CGFloat
    let progress: Double
    let primaryColor: Color
    let gradientColors: [Color]
    let isAscended: Bool // 满级状态
    
    // MARK: - 动态配置 (核心修改)
    // 满级时：0.0 ~ 1.0 (全圆)
    // 未满级：0.16 ~ 0.84 (底部缺口)
    private var startTrim: Double { isAscended ? 0.0 : 0.16 }
    private var endTrim: Double   { isAscended ? 1.0 : 0.84 }
    
    // 有效弧度长度
    private var arcLength: Double { endTrim - startTrim }
    
    // 动画配置：慢速、庄重
    private let closeAnimation = Animation.easeInOut(duration: 3.0)
    
 
    var body: some View {
        ZStack {
            // 1. 轨道 (暗色背景)
            Circle()
                .trim(from: CGFloat(startTrim), to: CGFloat(endTrim))
                .stroke(
                    Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .frame(width: ringSize, height: ringSize)
                // ✨ 动画：轨道缓慢合拢
                .animation(closeAnimation, value: isAscended)
            
           
            let ringGradient = AngularGradient(
                gradient: Gradient(
                    colors: isAscended
                        // 满级：同色渐变（看起来就是纯色，但类型没变）
                        ? [primaryColor, primaryColor]
                        // 未满级：灵气流转
                        : gradientColors
                ),
                center: .center,
                startAngle: .degrees(90),
                endAngle: .degrees(360)
            )
          
            // 3. 进度条 (亮色填充)
            Circle()
                .trim(from: CGFloat(startTrim), to: CGFloat(startTrim + (arcLength * progress)))
                .stroke(
                
                  ringGradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                // 满级时增加发光强度
                .shadow(color: primaryColor.opacity(isAscended ? 0.8 : 0.6), radius: isAscended ? 15 : 8)
                .frame(width: ringSize, height: ringSize)
                // ✨ 动画：进度条缓慢合拢
                .animation(closeAnimation, value: isAscended)
                // 进度本身的动画
                .animation(.spring(response: 0.5), value: progress)
          
          
            // 3. 进度光点 (流星头)
//            if progress > 0 && !isAscended {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 6, height: 6)
//                    .shadow(color: .white, radius: 4)
//                    .offset(x: ringSize / 2)
//                    // ⚠️ 注意：这里的 startTrim 和 arcLength 会随动画动态变化，
//                    // 从而保证光点在圆环合拢时也能平滑移动到正确位置
//                    .rotationEffect(.degrees(92.0 + (360.0 * (startTrim + arcLength * progress))))
//                    // ✨ 动画：光点位置跟随圆环变化
//                    .animation(closeAnimation, value: isAscended)
//                    // 进度本身的动画保持原样
//                    .animation(.spring(response: 0.5), value: progress)
//                   
//            }
            
        }
    }
}


struct BuffStatusBar: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        HStack(spacing: 8) {
            
            // 1. 点击增益 (Tap Buff)
            if let buff = gameManager.player.tapBuff, Date() < buff.expireAt {
              
                let isPositive = buff.bonusRatio >= 0
                let percent = Int(abs(buff.bonusRatio) * 100)
              
                HStack(spacing: 4) {
                  Image(systemName: isPositive
                        ? "hand.tap.fill"
                        : "bolt.slash.fill")
                  Text(isPositive ? "+\(percent)%" : "-\(percent)%")
                }
                .font(XiuxianFont.buffTag)

                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                  isPositive
                  ? Color.orange
                  : Color.black.opacity(0.7)
                )
                .clipShape(Capsule())
                .transition(.scale)
            }
            
            // 2. 自动增益 (Auto Buff)
            if let buff = gameManager.player.autoBuff, Date() < buff.expireAt {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                    Text("+\(Int(buff.bonusRatio * 100))%")
                }
                .font(XiuxianFont.buffTag)
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.8))
                .clipShape(Capsule())
                .transition(.scale)
            }
            
            // 3. 负面状态 (Debuff)
            if let debuff = gameManager.player.debuff, Date() < debuff.expireAt {
                HStack(spacing: 2) {
                    Image(systemName: "heart.slash.fill")
                    Text("道心不稳")
                }
                .font(XiuxianFont.buffTag)
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
                BottomActionButton(title:"立即突破" ,
                                   primaryColor: primaryColor) {
                  showBreakthrough = true
                }
                .padding(.bottom, 8)
                .transition(.opacity) // 切换时的淡入淡出
                
            } else {
                // --- 模式 B: 灵气数值 ---
                let isApproaching = gameManager.getCurrentProgress() >= 0.90
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    // 灵力数值
                    Text(gameManager.player.currentQi.xiuxianString)
                        .font(XiuxianFont.coreValue)
                        .foregroundColor(isApproaching ? primaryColor : .white)
                        .contentTransition(.numericText())
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    // 单位
                    Text("灵气")
                        .font(XiuxianFont.hudValue)
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

