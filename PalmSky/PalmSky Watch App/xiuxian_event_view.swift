import SwiftUI

// MARK: - Event View
struct EventView: View {
    let event: GameEvent
    @StateObject private var gameManager = GameManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.25, green: 0.15, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Title
                Text("奇遇")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                // Event title
                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(event.desc)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                
                Spacer()
                
                // Choices
                VStack(spacing: 12) {
                    ForEach(event.choices) { choice in
                        Button(action: {
                            gameManager.selectEventChoice(choice)
                            dismiss()
                        }) {
                            VStack(spacing: 4) {
                                Text(choice.text)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                // Show effect hint
                                if let effectHint = getEffectHint(choice.effect) {
                                    Text(effectHint)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
    }
    
    private func getEffectHint(_ effect: EventEffect) -> String? {
        switch effect.type {
        case .gainQi:
            if let value = effect.value {
                return "+\(Int(value)) 灵气"
            }
        case .loseQi:
            if let value = effect.value {
                return "-\(Int(value)) 灵气"
            }
        case .grantItem:
            return "+1 护身符"
        case .nothing:
            return nil
        case .gainTapRatioTemp, .gainAutoTemp:
            return "临时增益"
        }
        return nil
    }
}

// MARK: - Preview
struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView(event: GameEvent(
            id: "preview",
            title: "山间灵泉",
            desc: "泉眼冒出淡淡灵气，是否取一瓢？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "取来一瓢",
                    effect: EventEffect(type: .gainQi, value: 120)
                ),
                EventChoice(
                    id: "b",
                    text: "绕行而过",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "common"
        ))
    }
}
