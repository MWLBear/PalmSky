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

                  } else {
                    // 首次加载，创建场景并赋值给 State
                    Color.black
                      .onAppear {
                        self.mindDemonScene = createMindDemonScene(size: geo.size)
                      }
                  }
                  
                case .swordDefense:
                    // 你的旧游戏：御剑挡劫
                    SpriteView(scene: createSwordScene(size: geo.size))
                        .ignoresSafeArea()
                        
                case .inscription:
                    // 记忆游戏 (建议用纯 SwiftUI 写，更容易)
                    Text("阵法刻画开发中...")
                        .foregroundColor(.white)
                        
                case .skyRush:
                    // 跑酷游戏
                    Text("冲九霄开发中...")
                        .foregroundColor(.white)
                        
                default:
                    EmptyView()
                }
                
                // 顶部：退出/放弃按钮 (防止玩家卡死)
                VStack {
                    HStack {

                      // ✅ 修改为：Image + onTapGesture
                      Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8)) // 稍微调亮一点
                        .padding(10) // 增加点击热区
                        .contentShape(Rectangle()) // 确保透明区域也能响应点击
                        .onTapGesture {
                          // 震动反馈
                          HapticManager.shared.playIfEnabled(.click)
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
        case .mindDemon: return "斩除心魔"
        case .swordDefense: return "御剑挡劫"
        default: return "渡劫开始"
        }
    }
    
    func getGuideSubtitle() -> String {
        switch type {
        case .mindDemon: return "点击屏幕 以念破妄"
        case .swordDefense: return "点击屏幕 转换剑阵"
        default: return "点击屏幕"
        }
    }
  
  // 新增：不同游戏可以配不同图标
     func getGuideIcon() -> String {
         switch type {
         case .swordDefense: return "arrow.triangle.2.circlepath" // 旋转图标
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
    
    func createSwordScene(size: CGSize) -> SKScene {
        // ... 返回你之前的 SwordDefenseScene ...
        return SKScene() // 占位
    }
}
