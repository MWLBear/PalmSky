import SwiftUI

struct EventView: View {
    let event: GameEvent
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景：保持神秘紫
                Color.black.ignoresSafeArea()
              
                let colors = RealmColor.gradient(for: gameManager.player.level)
                let primaryColor = colors.last ?? .green
              
                RadialGradient(
                    gradient: Gradient(colors: [primaryColor.opacity(0.2), .clear]),
                    center: .top, startRadius: 10, endRadius: geo.size.height * 0.8
                ).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 1. 顶部 Header
                        VStack(spacing: 4) { // 间距调小一点，节省空间
                            Text(event.title)
                                .font(.title3.weight(.bold)) // 原生标题字号
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(NSLocalizedString("watch_event_header", comment: ""))
                                .font(.caption2.weight(.medium)) // caption2 比 footnote 更精致
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 12)
                        
                        // 2. 描述文案
                        Text(event.desc)
                            .font(.callout) // 正文默认大小
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 20)
                        
                        // 3. 选项列表
                        VStack(spacing: 10) { // 选项间距稍微紧凑一点
                            ForEach(event.choices) { choice in
                                Button {
                                    handleChoice(choice)
                                } label: {
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(choice.text)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .minimumScaleFactor(0.8) // 🔥 防止文字太长被截断
                                            
                                            // 收益预览
                                            if let hint = getEffectHint(choice.effect) {
                                                Text(hint)
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.horizontal, 14) // 左右内边距微调
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.12)) //稍微亮一点点
                                    .clipShape(RoundedRectangle(cornerRadius: 14)) // 圆角稍微小一点，更硬朗
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 10) // 整体边距
                }
            }
        }
        .onAppear {
          HapticManager.shared.playIfEnabled(.notification)

        }
    }
    
    // MARK: - 逻辑保持不变
    private func handleChoice(_ choice: EventChoice) {
      
        HapticManager.shared.playIfEnabled(.click)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            gameManager.selectEventChoice(choice)
        }
    }
    
  private func getEffectHint(_ effect: EventEffect) -> String? {
          switch effect.type {
          case .gainQi:
              return NSLocalizedString("watch_event_hint_gain", comment: "")
          case .loseQi:
              return NSLocalizedString("watch_event_hint_risk", comment: "")
          case .grantItem:
              return NSLocalizedString("watch_event_hint_item", comment: "")
          case .gainTapRatioTemp, .gainAutoTemp:
              return NSLocalizedString("watch_event_hint_buff", comment: "")
          case .gamble, .gambleTap, .gambleAuto:
              return NSLocalizedString("watch_event_hint_gamble", comment: "")
          case .nothing:
              return NSLocalizedString("watch_event_hint_none", comment: "")
          }
      }
}

#Preview {
    EventView(
        event: GameEvent(
            id: "evt_watch_0234",
            title: "神秘洞府",
            desc: "偶遇神秘洞府。机缘已至。",
            choices: [
                EventChoice(
                    id: "a",
                    text: "感悟",
                    effect: EventEffect(
                        type: .gainQi,
                        value: 170,
                        duration: nil
                    )
                ),
                EventChoice(
                    id: "b",
                    text: "放弃",
                    effect: EventEffect(
                        type: .nothing,
                        value: nil,
                        duration: nil
                    )
                )
            ],
            rarity: "common",
            minStage: "开光",
            maxStage: "辟谷"
        )
    )
}
