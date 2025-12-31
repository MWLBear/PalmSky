
import SwiftUI

struct BuffDetailView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    
                    // 1. 点击增益
                    if let buff = gameManager.player.tapBuff, Date() < buff.expireAt {
                        BuffRow(
                            icon: "hand.tap.fill",
                            color: buff.bonusRatio >= 0 ? .orange : .gray,
                            title: "机缘 · 顿悟",
                            desc: buff.bonusRatio >= 0 ? "点击收益提升 \(Int(buff.bonusRatio * 100))%" : "点击收益降低 \(Int(abs(buff.bonusRatio) * 100))%",
                            expireAt: buff.expireAt
                        )
                    }
                    
                    // 2. 自动增益
                    if let buff = gameManager.player.autoBuff, Date() < buff.expireAt {
                        BuffRow(
                            icon: "leaf.fill",
                            color: .green,
                            title: "天地 · 灵气",
                            desc: "自动修炼速度 +\(Int(buff.bonusRatio * 100))%",
                            expireAt: buff.expireAt
                        )
                    }
                    
                    // 3. 负面状态
                    if let debuff = gameManager.player.debuff, Date() < debuff.expireAt {
                        BuffRow(
                            icon: "heart.slash.fill",
                            color: .red,
                            title: "劫难 · 心魔", // 文案修饰一下
                            desc: "所有收益折损 \(Int((1.0 - debuff.multiplier) * 100))%",
                            expireAt: debuff.expireAt
                        )
                    }
                    
                    // 4. 空状态 (如果没有 Buff)
                    if !hasAnyBuff {
                        VStack(spacing: 15) {
                            Spacer().frame(height: 20)
                            Image(systemName: "wind")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("当前道心通明\n无增益亦无杂念")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .navigationTitle("状态详情")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black.ignoresSafeArea()) // 纯黑底
        }
    }
    
    var hasAnyBuff: Bool {
        let now = Date()
        let hasTap = (gameManager.player.tapBuff?.expireAt ?? .distantPast) > now
        let hasAuto = (gameManager.player.autoBuff?.expireAt ?? .distantPast) > now
        let hasDebuff = (gameManager.player.debuff?.expireAt ?? .distantPast) > now
        return hasTap || hasAuto || hasDebuff
    }
}

// MARK: - 优化后的行视图 (卡片风格)
struct BuffRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    let expireAt: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 头部：图标 + 标题 + 倒计时
          HStack(alignment: .top, spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize()
                
              Spacer(minLength: 0) // 允许 Spacer 缩到最小

                // 倒计时胶囊
                HStack(spacing: 0) {
                   //Image(systemName: "timer")
                    Text(expireAt, style: .timer) // 系统自动倒计时，非常省电
                        .monospacedDigit()
                        .fixedSize()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
            }
           Spacer(minLength: 0) // 允许 Spacer 缩到最小

           Divider().background(Color.white.opacity(0.01))
            // 描述
            Text(desc)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color(white: 0.12)) // 深灰背景
        .clipShape(RoundedRectangle(cornerRadius: 10))
        // 左边加一条颜色竖线，区分类型
        .overlay(
            HStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
}

#Preview("满状态展示") {
    let gm = GameManager.shared
    // 1. 造一个 10分钟后过期的点击 Buff
    gm.player.tapBuff = BuffStatus(bonusRatio: 0.5, expireAt: Date().addingTimeInterval(600))
    // 2. 造一个 5分钟后过期的自动 Buff
    gm.player.autoBuff = BuffStatus(bonusRatio: 1.0, expireAt: Date().addingTimeInterval(300))
    // 3. 造一个 1小时后过期的 Debuff
    gm.player.debuff = DebuffStatus(type: .unstableDao, multiplier: 0.7, expireAt: Date().addingTimeInterval(3600))
    
    return BuffDetailView()
        .environmentObject(gm)
}

#Preview("空状态展示") {
    let gm = GameManager.shared
    // 清空状态
    gm.player.tapBuff = nil
    gm.player.autoBuff = nil
    gm.player.debuff = nil
    
    return BuffDetailView()
        .environmentObject(gm)
}
