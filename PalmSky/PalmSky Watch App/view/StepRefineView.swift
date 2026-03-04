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
                Text(String(format: NSLocalizedString("watch_step_today_steps_format", comment: ""), healthManager.todaySteps.formatted()))
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
        if hasStepsToRefine { return NSLocalizedString("watch_step_status_tap_refine", comment: "") }
        if isMaxLimitReached { return NSLocalizedString("watch_step_status_maxed", comment: "") }
        return healthManager.todaySteps == 0 ? NSLocalizedString("watch_step_status_no_steps", comment: "") : NSLocalizedString("watch_step_status_done", comment: "")
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
                Text(NSLocalizedString("watch_step_badge_full", comment: ""))
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
                    Text(NSLocalizedString("watch_step_badge_rest", comment: ""))
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
                    Text(NSLocalizedString("watch_step_badge_claimed", comment: ""))
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
            gameManager.offlineToastMessage = NSLocalizedString("watch_step_toast_maxed", comment: "")
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
