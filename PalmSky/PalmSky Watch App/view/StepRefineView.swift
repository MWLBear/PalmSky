import SwiftUI

struct StepRefineRow: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var healthManager = WatchHealthManager.shared
    let themeColor: Color
    var onRefineSuccess: ((Double) -> Void)? = nil
    
    var body: some View {
        // 1. 判断是否达到上限
        let isMaxLimitReached = healthManager.todaySteps >= healthManager.MAX_DAILY_STEPS && healthManager.stepsAvailableToRefine <= 0
      
        Button(action: {
          
            if healthManager.stepsAvailableToRefine > 0 {
              // ✅ 优先级第一：只要有步数，先炼化！不管是不是超了上限
              handleRefineSteps()
            } else if isMaxLimitReached {
              // 🟠 优先级第二：没步数了，且到了上限，才提示“肉身极限”
              HapticManager.shared.playIfEnabled(.failure)
              gameManager.offlineToastMessage = "凡胎肉体已达极限，明日再来"
            }
          
        }) {
            HStack(spacing: 6) {
                iconView(isMaxed: isMaxLimitReached)
                
                infoView(isMaxed: isMaxLimitReached)
                  .layoutPriority(1)
              
                Spacer(minLength: 0)

                statusView(isMaxed: isMaxLimitReached)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        // ⚠️ 只有在“没步数”且“没达上限”时才禁用
        // 如果达上限了，允许点击(为了看提示)；如果有步数，允许点击(炼化)
        .disabled(healthManager.stepsAvailableToRefine <= 0 && !isMaxLimitReached)
        .onAppear {
            healthManager.requestPermission()
            healthManager.fetchTodaySteps()
        }
    }

    // MARK: - Subviews
    
    private func iconView(isMaxed: Bool) -> some View {
        // 达到上限变橙色，否则跟随主题色
        Image(systemName: "figure.walk")
            .font(.title3)
            .foregroundColor(isMaxed ? .orange : themeColor)
    }
    
  // MARK: - 左侧文字信息
    private func infoView(isMaxed: Bool) -> some View {
      VStack(alignment: .leading, spacing: 1) {
        
        // 第一行：状态文字
        if healthManager.stepsAvailableToRefine > 0 {
          Text("点击炼化") // 🟢
            .foregroundColor(.green)
        } else if isMaxed {
          Text("经脉已满") // 🟠
            .foregroundColor(.orange)
        } else {
          // ⚪️ 没满，也没得领
          if healthManager.todaySteps == 0 {
            Text("暂无步数") // 刚起床
              .foregroundColor(.gray)
          } else {
            Text("炼化完成") // 走过了，领完了
              .foregroundColor(.gray)
          }
        }
        
        // 第二行：今日步数 (保持不变)
        HStack(spacing: 2) {
          Text("今日 \(healthManager.todaySteps)步")
            .monospacedDigit()
            .font(XiuxianFont.buffTag)
            .foregroundColor(.gray)
        }
      }
    }
    
    // MARK: - 右侧按钮状态
    @ViewBuilder
    private func statusView(isMaxed: Bool) -> some View {
      if healthManager.stepsAvailableToRefine > 0 {
        // 🟢 有步数
        HStack(spacing: 0) {
          Text("+\(healthManager.stepsAvailableToRefine)")
            .font(XiuxianFont.caption)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(themeColor.opacity(0.25))
        .clipShape(Capsule())
        
      } else if isMaxed {
        // 🟠 达上限
        HStack(spacing: 2) {
          Image(systemName: "lock.fill")
            .font(.system(size: 10))
          Text("上限")
            .font(XiuxianFont.caption)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
        
      } else {
        // ⚪️ 没步数 (0步 或 已领完)
        HStack(spacing: 2) {
          if healthManager.todaySteps == 0 {
            // 0步显示脚印
            Image(systemName: "shoeprints.fill")
              .font(.system(size: 10))
            Text("休憩")
          } else {
            // 领完显示对号
            Image(systemName: "checkmark")
            Text("已领")
          }
        }
        .font(XiuxianFont.secondaryButton)
        .foregroundColor(.secondary.opacity(0.5))
        .fixedSize()
      }
    }
  
    
    private func handleRefineSteps() {
         let baseGain = gameManager.getCurrentTapGain()
         let gain = healthManager.refine(perStepValue: baseGain)
         if gain > 0 {
             gameManager.player.currentQi += gain
             gameManager.savePlayer()
             
             // 震动
             HapticManager.shared.playIfEnabled(.success)
           
             onRefineSuccess?(gain)
         }
    }
}
