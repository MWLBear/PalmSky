import Foundation
import Combine
import WatchKit


// MARK: - Game Manager
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var player: Player
    @Published var showBreakButton: Bool = false
    @Published var currentEvent: GameEvent?
    @Published var showEventView: Bool = false
    
    @Published var offlineToastMessage: String? = nil

  
    private var timer: Timer?
    private var eventCheckTimer: Timer?
    private var lastEventCheck: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    private let levelManager = GameLevelManager.shared
    private let userDefaultsKey = "savedPlayer"
    
    private init() {
        // Load saved player or create new
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Player.self, from: data) {
            self.player = decoded
        } else {
            self.player = Player()
        }
        
        checkBreakCondition()
        setupAutoSave()
    }
    
  // 在 init() 或者应用启动时调用

  // MARK: - 离线收益结算
      func calculateOfflineGain() {
          let now = Date()
          let lastTime = player.lastLogout
          
          // 计算物理离线时间
          let rawTimeDiff = now.timeIntervalSince(lastTime)
          
          // 1. 阈值检查：少于 5 分钟不算，避免切屏频繁弹窗
          if rawTimeDiff < 300 {
              // 虽然不结算收益，但要更新时间，防止玩家通过"频繁杀后台"来卡时间bug
              player.lastLogout = now
              savePlayer()
              return
          }
          
          // 2. ⚠️ 修正点：增加 12小时 (43200秒) 上限
          // 鼓励玩家每天早晚各看一次，增加粘性
          let maxOfflineSeconds: TimeInterval = 12 * 60 * 60
          let effectiveTime = min(rawTimeDiff, maxOfflineSeconds)
          
          // 3. 计算收益
          // 这里的 level 应该是当前 level。
          // (进阶逻辑：其实如果跨越了很久，应该模拟每秒增长，但为了性能，按当前等级算即可，算作一种"福利")
          let gainPerSec = levelManager.autoGain(level: player.level)
          
          // 4. 离线打折 (0.8)
          let offlineTotal = gainPerSec * effectiveTime * 0.8
          
          if offlineTotal > 0 {
              player.currentQi += offlineTotal
              
              // 记录日志或准备弹窗内容 (可选)
              print("=== 离线结算 ===")
              print("离线时长: \(Int(rawTimeDiff))秒")
              print("有效时长: \(Int(effectiveTime))秒")
              print("获得灵气: \(offlineTotal.xiuxianString)")
              
              let timeStr = effectiveTime.formatTime()

              DispatchQueue.main.async {
                self.offlineToastMessage = "闭关\(timeStr)，灵气 +\(offlineTotal.xiuxianString)"
              }
            
              // 触发 UI 提示 (如果你做了弹窗的话)
              // showOfflineAlert(amount: offlineTotal)
          }
          
          // 5. 更新时间并保存
          player.lastLogout = now
          savePlayer()
      }
  
  
    // MARK: - Lifecycle
    func startGame() {
        startAutoGain()
        startEventCheck()
    }
    
    func pauseGame() {
        timer?.invalidate()
        eventCheckTimer?.invalidate()
        savePlayer()
    }
    
  
    // MARK: - Auto Gain
    // 🔴 新增：计算当前的每秒收益 (带 Debuff 检查)
    func getCurrentAutoGain() -> Double {
      var gain = levelManager.autoGain(level: player.level)
      
      
      // 1. 检查 Auto Buff (增益)
      if let buff = player.autoBuff {
        if Date() < buff.expireAt {
          // 公式：基础值 * (1 + 增益比例)
          // 例如 value=0.5, 则乘 1.5
          gain *= (1.0 + buff.bonusRatio)
        } else {
          player.autoBuff = nil // 过期清理
        }
      }
      
      // 检查 Debuff
      if let debuff = player.debuff {
        if Date() < debuff.expireAt {
          // Debuff 生效中，收益打折
          gain *= debuff.multiplier
        } else {
          // Debuff 已过期，清理掉
          // 注意：这里不会立即保存，会在下一次 tick 或退出时保存
          player.debuff = nil
        }
      }
      
      return gain
    }
    
    // MARK: - Auto Gain
    private func startAutoGain() {
        timer?.invalidate()
        
        guard player.settings.autoGainEnabled else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick(deltaSeconds: 1.0)
        }
    }
    
    private func tick(deltaSeconds: Double) {
//        let gain = levelManager.autoGain(level: player.level) * deltaSeconds
        let gain = getCurrentAutoGain() * deltaSeconds
        player.currentQi += gain
        checkBreakCondition()
    }
    
    // MARK: - Tap Action
    func onTap() {
        var gain = levelManager.tapGain(level: player.level)
      
        // ✨ 新增：检查 Tap Buff
        if let buff = player.tapBuff {
          if Date() < buff.expireAt {
            gain *= (1.0 + buff.bonusRatio)
          } else {
            player.tapBuff = nil // 过期清理
          }
        }
      
        player.currentQi += gain
        
        if player.settings.hapticEnabled {
            HapticManager.shared.play(.light)
        }
        
        checkBreakCondition()
    }
    
    // MARK: - Breakthrough
    private func checkBreakCondition() {
        let cost = levelManager.breakCost(level: player.level)
        showBreakButton = player.currentQi >= cost && player.level < GameConstants.MAX_LEVEL
    }
    
    func attemptBreak() -> Bool {
        guard showBreakButton else { return false }
        
        let successRate = levelManager.breakSuccess(level: player.level)
        let roll = Double.random(in: 0...1)
        let previousLevel = player.level
        let cost = levelManager.breakCost(level: previousLevel)
        
        if roll <= successRate {
            // Success
            player.level += 1
            player.currentQi = max(0, player.currentQi - cost)
            showBreakButton = false
            
            if player.settings.hapticEnabled {
                HapticManager.shared.play(.success)
            }
            
            savePlayer()
            return true
        } else {
            // Failure: lose 10% qi
            let penaltyRate = levelManager.breakFailPenalty(level: player.level)
            
            // 2. 执行扣除
            // 比如 penaltyRate 是 0.2 (20%)，那么剩余就是 0.8
            player.currentQi *= (1.0 - penaltyRate)

          
            if player.level >= 90 {
              // 1小时内，自动收益降为 70%
              let expireDate = Date().addingTimeInterval(3600)
              player.debuff = DebuffStatus(type: .unstableDao, multiplier: 0.7, expireAt: expireDate)
              
              // 弹窗提示 (用 Toast)
              DispatchQueue.main.async {
                self.offlineToastMessage = "道心受损，吸纳效率降低 (持续1小时)"
              }
            }
            
            if player.settings.hapticEnabled {
                HapticManager.shared.play(.error)
            }
            
            checkBreakCondition()
            savePlayer()
            return false
        }
    }
    
    // MARK: - Event System
    private func startEventCheck() {
        eventCheckTimer?.invalidate()
        
        eventCheckTimer = Timer.scheduledTimer(
            withTimeInterval: GameConstants.EVENT_CHECK_INTERVAL_SECONDS,
            repeats: true
        ) { [weak self] _ in
            self?.checkForEvent()
        }
    }
    
    private func checkForEvent() {
        guard !showEventView else { return }
        
        let roll = Double.random(in: 0...1)
        if roll <= GameConstants.EVENT_PROBABILITY_PER_CHECK {
            triggerRandomEvent()
        }
    }
    
    private func triggerRandomEvent() {
        // Get random event from pool
        if let event = EventPool.shared.randomEvent(playerLevel: player.level) {
          
            // ✅ 打乱 choices 顺序（只影响当前展示）
            let shuffledEvent = GameEvent(
              id: event.id,
              title: event.title,
              desc: event.desc,
              choices: event.choices.shuffled(),
              rarity: event.rarity,
              minStage: event.minStage,
              maxStage: event.maxStage
            )
            
            currentEvent = shuffledEvent
            showEventView = true
        }
    }
    
    func selectEventChoice(_ choice: EventChoice) {
        applyEventEffect(choice.effect)
        showEventView = false
        currentEvent = nil
    }

    private func applyEventEffect(_ effect: EventEffect) {
      switch effect.type {
      case .gainQi:
        if let value = effect.value {
          player.currentQi += value
          // ✨ 新增：设置 Toast 消息，回到主页时自动弹出
          DispatchQueue.main.async {
            self.offlineToastMessage = "奇遇收获 灵气 +\(Int(value))"
          }
        }
      case .loseQi:
        if let value = effect.value {
          player.currentQi = max(0, player.currentQi - value)
          // ✨ 新增：扣除提示
          DispatchQueue.main.async {
            self.offlineToastMessage = "遭遇意外 灵气 -\(Int(value))"
          }
        }
      case .grantItem:
        player.items.protectCharm += 1
        // ✨ 新增：获得道具提示
        DispatchQueue.main.async {
          self.offlineToastMessage = "获得宝物 [护身符]"
        }
      case .gainTapRatioTemp:
        // 逻辑处理：点击增益
        // value 例如 0.5 (代表+50%), duration 例如 60 (代表60秒)
        if let val = effect.value, let duration = effect.duration {
          let expireDate = Date().addingTimeInterval(duration)
          
          // 更新 Player 状态
          player.tapBuff = BuffStatus(bonusRatio: val, expireAt: expireDate)
          
          // 格式化时间字符串 (如 "60秒" 或 "2分钟")
          let timeStr = Int(duration) < 60 ? "\(Int(duration))秒" : "\(Int(duration)/60)分钟"
          let percent = Int(val * 100)
          
          // 弹窗提示
          DispatchQueue.main.async {
            self.offlineToastMessage = "感悟提升 点击效果 +\(percent)% (\(timeStr))"
          }
        }
        
      case .gainAutoTemp:
        // 逻辑处理：自动增益
        if let val = effect.value, let duration = effect.duration {
          let expireDate = Date().addingTimeInterval(duration)
          
          // 更新 Player 状态
          player.autoBuff = BuffStatus(bonusRatio: val, expireAt: expireDate)
          
          // 格式化提示
          let timeStr = Int(duration) < 60 ? "\(Int(duration))秒" : "\(Int(duration)/60)分钟"
          let percent = Int(val * 100)
          
          DispatchQueue.main.async {
            self.offlineToastMessage = "道心稳固 自动修炼 +\(percent)% (\(timeStr))"
          }
        }
        
      case .nothing:
        break
      }
      
      checkBreakCondition()
      savePlayer()
    }
  
    // MARK: - Settings
    func toggleHaptic() {
        player.settings.hapticEnabled.toggle()
        savePlayer()
    }
    
    func toggleAutoGain() {
        player.settings.autoGainEnabled.toggle()
        if player.settings.autoGainEnabled {
            startAutoGain()
        } else {
            timer?.invalidate()
        }
        savePlayer()
    }
    
    func resetGame() {
        player = Player()
        showBreakButton = false
        currentEvent = nil
        showEventView = false
        savePlayer()
    }
    
    // MARK: - Persistence
    private func setupAutoSave() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.savePlayer()
        }
    }
    
    func savePlayer() {
        player.lastLogout = Date()
        if let encoded = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Getters
    func getCurrentProgress() -> Double {
        return levelManager.progress(currentQi: player.currentQi, level: player.level)
    }
    
    func getCurrentRealm() -> String {
        return levelManager.realmDescription(for: player.level)
    }
    
    func getRealmShort() -> String {
        return levelManager.stageName(for: player.level)
    }
  
    func getLayerName() -> String {
        return levelManager.layerName(for: player.level)
    }
  
}

extension GameManager {
  // MARK: - Break Mini Result (for CrownBalanceView)
  func applyBreakResult(success: Bool) {
      let cost = levelManager.breakCost(level: player.level)

      if success {
          // 成功突破
          player.level += 1
          player.currentQi = max(0, player.currentQi - cost)

          if player.settings.hapticEnabled {
              HapticManager.shared.play(.success)
          }
      } else {
          // 失败惩罚
          player.currentQi *= 0.9

          if player.settings.hapticEnabled {
              HapticManager.shared.play(.error)
          }
      }

      checkBreakCondition()
      savePlayer()
  }

  
}

extension GameManager {
    
    /// 获取当前等级失败时的惩罚百分比（整数）
    /// 例如：返回 20 代表 20%
    var currentPenaltyPercentage: Int {
        let rawRate = levelManager.breakFailPenalty(level: player.level)
        return Int(rawRate * 100)
    }
}
