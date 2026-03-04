//
//  MiniGameContainer.swift
//  PalmSky Watch App
//
//  Created by mac on 12/25/25.
//

import SwiftUI
import SpriteKit

struct MiniGameContainer: View {
    let type: GameLevelManager.TribulationGameType
    let level: Int
    @Binding var isPresented: Bool
    let onFinish: (Bool) -> Void
  
  // 🔥 关键修改 1：使用 @State 保存场景实例
     // 这样不仅能防止重绘导致游戏重置，还能让我们在 onTapGesture 里访问到它
    @State private var mindDemonScene: MindDemonScene?
  
    @State private var showGuideText = true
    @State private var swordDefenseScene: SwordDefenseScene?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch type {
                case .mindDemon:
                  // 🔥 关键修改 2：初始化与显示逻辑
                  if let scene = mindDemonScene {
                    SpriteView(scene: scene)
                      .ignoresSafeArea()
                    // 🔥 关键修改 3：SwiftUI 点击 -> 调用 SpriteKit 方法
                      .onTapGesture {
                        scene.fireNeedle() // 调用场景里的发射方法
                      }
                      // 🔥 关键修改 4：清理场景，防止音效和动作泄漏
                      .onDisappear {
                        cleanupMindDemonScene()
                      }

                  } else {
                    // 首次加载，创建场景并赋值给 State
                    Color.black
                      .onAppear {
                        self.mindDemonScene = createMindDemonScene(size: geo.size)
                      }
                  }
                  
                case .swordDefense:
                    // 你的旧游戏：御剑挡劫
                    if let scene = swordDefenseScene {
//                        #if os(iOS)
//                        SpriteView(scene: scene, options: [.allowsTransparency], debugOptions: [.showsPhysics])
//                            .ignoresSafeArea()
//                            .onTapGesture { location in
//                               scene.handleDrop(at: location)
//                            }
//                        #else
                      SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .onTapGesture { location in
                          scene.handleDrop(at: location)
                        }
                        .onDisappear {
                          cleanupSwordDefenseScene()
                        }
                    
                    } else {
                        Color.black
                            .onAppear {
                                self.swordDefenseScene = createSwordScene(size: geo.size)
                            }
                    }
                        
                case .inscription:
       
                  InscriptionGameView(level: level, startWhenReady: !showGuideText) { isWin in
                    onFinish(isWin)
                   // isPresented = false
                  }

                        
                case .skyRush:
                    // 跑酷游戏
                    Text(NSLocalizedString("watch_game_skyrush_dev", comment: ""))
                        .foregroundColor(.white)
                        
                default:
                    EmptyView()
                }
                
                // 顶部：退出/放弃按钮 (防止玩家卡死)
                VStack {
                    HStack {
                      #if os(iOS)
                      Spacer().frame(width: 8)
                      #endif

                      // ✅ 修改为：Image + onTapGesture
                      Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8)) // 稍微调亮一点
                        .padding(10) // 增加点击热区
                        .contentShape(Rectangle()) // 确保透明区域也能响应点击
                        .onTapGesture {
                          // 震动反馈
                          HapticManager.shared.playIfEnabled(.click)
                          cleanupMindDemonScene() // 🔥 退出时也清理
                          cleanupSwordDefenseScene()
                          isPresented = false
                          // onFinish(false) // 如果需要回调失败逻辑可以加上
                        }
                        .zIndex(999) // 🔥 确保层级最高，不被遮挡
                      
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
              
              // 2. ✨ 引导层 (已封装)
              GameGuideView(
                title: getGuideTitle(),
                subtitle: getGuideSubtitle(),
                icon: getGuideIcon(),
                isShowing: $showGuideText
              )              
            }
        }
    }
    
  
  // MARK: - 动态文案 (根据游戏类型变化)
    
    func getGuideTitle() -> String {
        switch type {
        case .mindDemon: return NSLocalizedString("watch_game_guide_title_mind", comment: "")
        case .swordDefense: return NSLocalizedString("watch_game_guide_title_sword", comment: "")
        case .inscription: return NSLocalizedString("watch_game_guide_title_inscription", comment: "")
        case .skyRush: return NSLocalizedString("watch_game_guide_title_rush", comment: "")
        default: return NSLocalizedString("watch_game_guide_title_default", comment: "")
        }
    }
    
    func getGuideSubtitle() -> String {
        switch type {
        case .mindDemon: return NSLocalizedString("watch_game_guide_subtitle_mind", comment: "")
        case .swordDefense: return NSLocalizedString("watch_game_guide_subtitle_sword", comment: "")
        case .inscription: return NSLocalizedString("watch_game_guide_subtitle_inscription", comment: "")
        default: return NSLocalizedString("watch_game_guide_subtitle_default", comment: "")
        }
    }
  
  // 新增：不同游戏可以配不同图标
     func getGuideIcon() -> String {
         switch type {
         case .swordDefense: return "arrow.triangle.2.circlepath" // 旋转图标
         case .inscription: return "brain.head.profile" // 记忆阵法
         default: return "hand.tap.fill" // 点击图标
         }
     }
  
  
    // 工厂方法：创建场景
    func createMindDemonScene(size: CGSize) -> MindDemonScene { // 注意返回值类型改具体一点方便调用
          let scene = MindDemonScene(size: size)
          scene.scaleMode = .aspectFill
          scene.gameLevel = level
          scene.onGameOver = onFinish
          // Re-run setup with correct level
          scene.setupGame()
          print("level===",level)
          return scene
      }
    
    #if DEBUG
    private let debugSwordLevel: Int? = nil // 设置为 4...7 进行调试
    #endif
    
    func createSwordScene(size: CGSize) -> SwordDefenseScene {
        let scene = SwordDefenseScene(size: size)
        scene.scaleMode = .aspectFill
        let stage = (level - 1) / 9
        #if DEBUG
        scene.gameLevel = debugSwordLevel ?? stage
        #else
        scene.gameLevel = stage
        #endif
        scene.applyGameLevel()
        scene.onGameOver = onFinish
        return scene
    }
    
    // 🔥 新增：清理 MindDemonScene 的方法
    private func cleanupMindDemonScene() {
        guard let scene = mindDemonScene else { return }
        
        // 停止所有动作（包括环境雷电循环）
        scene.removeAllActions()
        
        // 停止场景中所有节点的动作
        scene.removeAllChildren()
        
        // 清空场景引用
        mindDemonScene = nil
        
        print("MindDemonScene 已清理")
    }
  
    private func cleanupSwordDefenseScene() {
        guard let scene = swordDefenseScene else { return }
        
        scene.removeAllActions()
        scene.removeAllChildren()
        swordDefenseScene = nil
        
        print("SwordDefenseScene 已清理")
    }
}
