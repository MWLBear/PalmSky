import SwiftUI

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
                    
                    // ✨ 逻辑已下沉到 GameManager
                    gameManager.requestBreakthrough {
                        // 只有通过检查才会执行这里
                        showBreakthrough = true
                    }
                    HapticManager.shared.playIfEnabled(.click)
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
