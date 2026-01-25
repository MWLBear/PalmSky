import SwiftUI

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
                // ✨ 修复高度不一致
                .frame(height: 15)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                // .padding(.vertical, 2) // 移除垂直 padding，靠 frame 撑开
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
                // ✨ 修复高度不一致
                .frame(height: 15)
                .foregroundColor(.black)
                .padding(.horizontal, 6)
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
                // ✨ 修复高度不一致
                .frame(height: 15)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .background(Color.red.opacity(0.8))
                .clipShape(Capsule())
                .transition(.scale)
            }
        }
        .onTapGesture {
            // 只有当有 Buff 时才允许点击
            if hasAnyBuff {
                showBuffDetail = true
                HapticManager.shared.playIfEnabled(.click)
            }
        }
        .sheet(isPresented: $showBuffDetail) {
            BuffDetailView()
        }
        // 当状态变化时，添加平滑动画
        .animation(.spring(), value: gameManager.player.tapBuff?.expireAt)
        .animation(.spring(), value: gameManager.player.autoBuff?.expireAt)
    }
    
    @State private var showBuffDetail = false
    
    // 助手属性：判断是否有 Buff
    var hasAnyBuff: Bool {
        let now = Date()
        let hasTap = (gameManager.player.tapBuff?.expireAt ?? .distantPast) > now
        let hasAuto = (gameManager.player.autoBuff?.expireAt ?? .distantPast) > now
        let hasDebuff = (gameManager.player.debuff?.expireAt ?? .distantPast) > now
        return hasTap || hasAuto || hasDebuff
    }
}
