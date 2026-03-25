import SwiftUI

struct RootPagerView: View {
    @EnvironmentObject var gameManager: GameManager

    @State private var page = 0
    @State private var showBreakthrough = false
    @State private var showCelebration = false
    @State private var showReview = false
    @ObservedObject var recordManager = RecordManager.shared
    
    // 首次提示相关
    @AppStorage("hasSeenSwipeTutorial") private var hasSeenSwipeTutorial = false
    @State private var showSwipeTutorial = false

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
          
            #if os(watchOS)
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
            #endif
          
            .sheet(isPresented: $gameManager.showPaywall) {
                PaywallView()
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
          
          
            #if os(iOS)
          
            // 6. 突破界面 (Overlay 覆盖)
            if showBreakthrough {
                BreakthroughView(isPresented: $showBreakthrough)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(4)
            }
            
            // 7. 奇遇事件 (Overlay 覆盖)
            if gameManager.showEventView {
              
              if let event = gameManager.currentEvent {
                NavigationView {
                  EventView(event: event)
                }
               // .toolbar(.hidden, for: .navigationBar)
              }
              
            }
          
            #endif
            
            // 🆕 左滑提示动画
            if showSwipeTutorial && page == 0 {
                SwipeTutorialView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .zIndex(5)
            }
        }
        .onChange(of: page) { _, newPage in
            // 用户滑动后，隐藏提示并标记已看过
            if showSwipeTutorial {
                withAnimation {
                    showSwipeTutorial = false
                }
                hasSeenSwipeTutorial = true
            }
        }
        .onAppear {
            WatchHealthManager.shared.requestPermission()
            // 首次进入且未看过提示，延迟3秒显示
            if !hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSwipeTutorial = true
                    }
                    
                    // 3秒后自动消失
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            showSwipeTutorial = false
                        }
                        hasSeenSwipeTutorial = true
                    }
                }
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
                
                // 2. 先刷新健康数据，再结算离线收益，避免睡眠查询慢返回导致加成丢失
                WatchHealthManager.shared.requestPermission {
                    gameManager.calculateOfflineGain()
                }
            } else if newPhase == .background {
                // App 切后台，保存时间
                print("🌙 Background: 彻底闭关")
                // ⚡ 修复：标记 App 为非活跃状态
                gameManager.isAppActive = false
              
                gameManager.player.lastLogout = Date() // 更新时间
                gameManager.savePlayer()
                gameManager.flushCloudBackup()
              
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
    @State private var allowAscendAnimation = false
  
   // ✨ 新增：控制境界详情页显示
   @State private var showRealmDetail = false
  
  
    #if os(watchOS)
    let visualOffsetY: CGFloat = 15.0
    #elseif os(iOS)
    let visualOffsetY: CGFloat = 0.0
    #endif
  
    //let offsetY = 15.0
  
    var body: some View {
        GeometryReader { geo in
            // 核心尺寸计算
            let screenWidth = geo.size.width
          
            #if os(watchOS)
            let ringSize = screenWidth * 0.90 // 圆环撑满 90% 屏幕
            #elseif os(iOS)
            let ringSize = screenWidth - 15 // 手机占满中间的位置
            #endif
          
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
                  isAscended: visualIsAscended,
                  animateAscend: allowAscendAnimation
                )
                .offset(y: visualIsAscended ? 0 : visualOffsetY)
           
                // 3. 物理太极 (居中)
                TaijiView(
                    level: gameManager.player.level,
                    triggerImpulse: gameManager.refineEvent?.id, // 绑定事件ID
                    onTap: {
                      if !gameManager.isAscended {
                          gameManager.onTap()
                        } else {
                          HapticManager.shared.playIfEnabled(.click)
                        }
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            pulse = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            pulse = false
                        }
                    })
                .frame(width: taijiSize, height: taijiSize)
                .scaleEffect(pulse ? 1.08 : 1.0) // 更有力的跳动
                .offset(y: visualIsAscended ? 0 : visualOffsetY)

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
                    #if os(iOS)
                    .offset(y: -10)
                    #endif
                    .onTapGesture {
                      showRealmDetail = true
                    }
                    
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
                      #if os(watchOS)
                        .padding(.bottom, 0)
                      #elseif os(iOS)
                          .padding(.bottom, 10)
                      #endif
                     
                    }
                  }
                }
                .ignoresSafeArea() // 这一步很关键，允许文字推到最边缘
            }
        }
        .ignoresSafeArea()
      
        #if os(iOS)
        .navigationTitle(NSLocalizedString("watch_main_nav_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        #endif
      
        #if os(watchOS)
        .navigationBarHidden(true)
        #endif
        .toast(message: $gameManager.offlineToastMessage)

      // ✨ 挂载 Sheet 弹窗
        .sheet(isPresented: $showRealmDetail) {
          WatchRealmListView(
            currentLevel: gameManager.player.level,
            reincarnationCount: gameManager.player.reincarnationCount
          )
        }
      
        .onOpenURL { url in
            print("🚀 Deep link received: \(url.absoluteString)")
            
            if url.absoluteString == "palmSky://store" {
                // 延迟一点，等界面加载完，弹出付费墙
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  gameManager.showPaywall = true
                }
            }
          
            if url.absoluteString == "palmSky://breakthrough" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  showBreakthrough = true
                }
            }
        }
      
        .onAppear {
            gameManager.startGame()
            // 已满级时直接合上（无动画）
            visualIsAscended = gameManager.isAscended
            allowAscendAnimation = false
        }
        .onChange(of: gameManager.isAscended) { _, isAscended in
            if isAscended {
                // 第一次达成满级时才动画合拢
                allowAscendAnimation = true
                withAnimation(.easeInOut(duration: 3.0)) {
                    visualIsAscended = true
                }
            }
        }
        // 监听炼化事件
        .onChange(of: gameManager.refineEvent) { _, newEvent in
            if let event = newEvent {
                // 触发通用 Toast
                gameManager.offlineToastMessage = String(
                    format: NSLocalizedString("watch_main_toast_refine_gain_format", comment: ""),
                    event.amount.xiuxianString
                )
                
                // 震动
                HapticManager.shared.playIfEnabled(.success)
            }
        }
      
        .onChange(of: showBreakthrough) {oldShowing, isShowing in
          
          if !isShowing {
            if gameManager.isAscended {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 不强制动画，避免重复合拢
                visualIsAscended = true
              }
            }
          }
        }
        .alert(
            NSLocalizedString("cloud_restore_alert_title", comment: ""),
            isPresented: $gameManager.showCloudRestorePrompt
        ) {
            Button(NSLocalizedString("cloud_restore_alert_confirm", comment: "")) {
                gameManager.restoreFromCloudBackup()
            }
            Button(NSLocalizedString("cloud_restore_alert_decline", comment: ""), role: .cancel) {
                gameManager.declineCloudRestore()
            }
        } message: {
            Text(
                String(
                    format: NSLocalizedString("cloud_restore_alert_message_format", comment: ""),
                    gameManager.pendingCloudRestoreRealmSummary
                )
            )
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
