import SwiftUI

struct StepRefineRow: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var healthManager = WatchHealthManager.shared
    let themeColor: Color
    var onRefineSuccess: ((Double) -> Void)? = nil
    
    // 计算属性
    private var isMaxLimitReached: Bool {
        healthManager.todaySteps >= healthManager.MAX_DAILY_STEPS && healthManager.stepsAvailableToRefine <= 0
    }
    
    private var hasStepsToRefine: Bool {
        healthManager.stepsAvailableToRefine > 0
    }
    
    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 6) {
                // 顶部：状态行
                HStack(spacing: 6) {
                    // 图标
                    Image(systemName: "figure.walk")
                        .font(.body)
                        .foregroundColor(statusColor)
                    
                    // 状态文字
                    Text(statusText)
                        .foregroundColor(statusColor)
                    
                    Spacer(minLength: 0)
                    
                    // 徽章
                    badgeView
                }
                
                // 底部：今日步数
                Text("今日 \(healthManager.todaySteps.formatted()) 步")
                    .font(XiuxianFont.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasStepsToRefine && !isMaxLimitReached)
        .onAppear {
            healthManager.requestPermission()
            healthManager.fetchTodaySteps()
        }
    }
    
    // MARK: - 状态颜色
    private var statusColor: Color {
        if hasStepsToRefine { return .green }
        if isMaxLimitReached { return .orange }
        return .gray
    }
    
    // MARK: - 状态文字
    private var statusText: String {
        if hasStepsToRefine { return "点击炼化" }
        if isMaxLimitReached { return "经脉已满" }
        return healthManager.todaySteps == 0 ? "暂无步数" : "炼化完成"
    }
    
    // MARK: - 右侧徽章
    @ViewBuilder
    private var badgeView: some View {
        if hasStepsToRefine {
            // 🟢 可炼化
            Text("+\(healthManager.stepsAvailableToRefine.formatted())")
                .font(XiuxianFont.caption)
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeColor.opacity(0.25))
                .clipShape(Capsule())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
          
            
        } else if isMaxLimitReached {
            // 🟠 达上限 - 简洁设计
            HStack(spacing: 3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                Text("已满")
            }
            .font(.caption2)
            .foregroundColor(.orange.opacity(0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.12))
            .clipShape(Capsule())
            
        } else {
            // ⚪️ 已完成 / 无步数 - 简洁设计
            if healthManager.todaySteps == 0 {
                HStack(spacing: 3) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 9))
                    Text("休憩")
                }
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                    Text("已领")
                }
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - 点击处理
    private func handleTap() {
        if hasStepsToRefine {
            handleRefineSteps()
        } else if isMaxLimitReached {
            HapticManager.shared.playIfEnabled(.failure)
            gameManager.offlineToastMessage = "凡胎肉体已达极限，明日再来"
        }
    }
    
    private func handleRefineSteps() {
        let baseGain = gameManager.getCurrentTapGain()
        let gain = healthManager.refine(perStepValue: baseGain)
        if gain > 0 {
            gameManager.player.currentQi += gain
            gameManager.savePlayer()
            HapticManager.shared.playIfEnabled(.success)
            onRefineSuccess?(gain)
        }
    }
}
