import Foundation
import Combine
#if os(watchOS)
import WatchKit
#endif

let debugAscended = false // 九天玄仙8层-测试开关

// MARK: - Game Manager
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // 护身符商业化提示类型：首次教学 / 中后期提醒
    enum CharmUpsellPrompt {
        case intro
        case reminder
    }
    
    @Published var player: Player
    @Published var showBreakButton: Bool = false
    @Published var currentEvent: GameEvent?
    @Published var showEventView: Bool = false
    
    @Published var offlineToastMessage: String? = nil

   // 新增：控制是否显示大结局视图
    @Published var showEndgame: Bool = false
    
    // 🚨 新增：控制付费墙显示
    @Published var showPaywall: Bool = false
  
   // 新增计算属性
    var isAscended: Bool {
      player.level >= GameConstants.MAX_LEVEL
    }
    
    // ✨ 步数炼化事件 (用于触发主页动画)
    struct RefineEvent: Equatable {
        let id = UUID()
        let amount: Double
    }
    @Published var refineEvent: RefineEvent?

  
    private var mainLoopTimer: Timer?  // ⚡ 性能优化：合并原先的 3 个定时器
    private var mainLoopTickCount: Int = 0
    private var lastEventCheck: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // ⚡ 修复：跟踪 App 是否处于活跃状态，避免息屏时弹出事件
    var isAppActive: Bool = true

    private let levelManager = GameLevelManager.shared
    
  // 记录上次同步给手机的时间
    private var lastPhoneSyncTime: Date = .distantPast
  
    private init() {
        // Load saved player or create new
      if let data = UserDefaults.standard.data(forKey: SkyConstants.UserDefaults.userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Player.self, from: data) {
            self.player = decoded
        } else {
            self.player = Player()
        }
      
      // 👇👇👇【测试代码】开启上帝模式 👇👇👇
        // 这一段在测试完后记得删除或注释掉
//        if debugAscended {
//            self.player.level = 143 // 设定为满级前一级
//            self.player.currentQi = 999999999_999999 // 给无限灵气
//            // 👆👆👆【测试代码】结束 👆👆👆
//        }
      
        checkBreakCondition()
        // ⚡ 性能优化：setupAutoSave 已合并到 startMainLoop 中
      
        // ✨ 新增：请求通知权限
        NotificationManager.shared.requestPermission()
        
        // ✨ 同步震动设置到 HapticManager
        HapticManager.shared.isEnabled = self.player.settings.hapticEnabled
    }
    
  // 在 init() 或者应用启动时调用

  // MARK: - 离线收益结算
      func calculateOfflineGain() {
        
          // ✅ 修正：满级后不再结算离线收益
          if player.level >= GameConstants.MAX_LEVEL {
            return
          }
          
          let now = Date()
          let lastTime = player.lastLogout
          
          print("calculateOfflineGain - now ",now)

          // 计算物理离线时间
          let rawTimeDiff = now.timeIntervalSince(lastTime)
          
          print("calculateOfflineGain - rawTimeDiff ",rawTimeDiff)

          // 1. 阈值检查：少于 5 分钟不算，避免切屏频繁弹窗
          if rawTimeDiff < 300 {
              // 虽然不结算收益，但要更新时间，防止玩家通过"频繁杀后台"来卡时间bug
              player.lastLogout = now
              savePlayer()
              return
          }
          print("calculateOfflineGain - rawTimeDiff",rawTimeDiff)
          // 2. ⚠️ 修正点：增加 12小时 (43200秒) 上限
          // 鼓励玩家每天早晚各看一次，增加粘性
          //let maxOfflineSeconds: TimeInterval = 12 * 60 * 60
        
        // 🔥 核心修改：动态获取上限
          let isPro = PurchaseManager.shared.hasAccess
          let maxOfflineSeconds = isPro ? SkyConstants.PRO_OFFLINE_LIMIT : SkyConstants.FREE_OFFLINE_LIMIT
        
          let effectiveTime = min(rawTimeDiff, maxOfflineSeconds)
          
          // 3. 计算收益
          // 这里的 level 应该是当前 level。
          // (进阶逻辑：其实如果跨越了很久，应该模拟每秒增长，但为了性能，按当前等级算即可，算作一种"福利")
          let gainPerSec = levelManager.autoGain(level: player.level,reincarnation: player.reincarnationCount)
          
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

              if !isPro && rawTimeDiff > maxOfflineSeconds {
                DispatchQueue.main.async {
                  self.offlineToastMessage = String(
                    format: NSLocalizedString("watch_toast_offline_capped_format", comment: ""),
                    timeStr,
                    offlineTotal.xiuxianString
                  )
                }
              } else {
                DispatchQueue.main.async {
                  self.offlineToastMessage = String(
                    format: NSLocalizedString("watch_toast_offline_gain_format", comment: ""),
                    timeStr,
                    offlineTotal.xiuxianString
                  )
                }
              }
            
              // 触发 UI 提示 (如果你做了弹窗的话)
              // showOfflineAlert(amount: offlineTotal)
          }
          
          // 5. 清理过期状态 (简单的懒人清理法)
          // 上线了，发现 Buff 时间过了，就直接删掉
          if let buff = player.autoBuff, buff.expireAt < now { player.autoBuff = nil }
          if let buff = player.tapBuff, buff.expireAt < now { player.tapBuff = nil }
          if let debuff = player.debuff, debuff.expireAt < now { player.debuff = nil }
          
          // 6. 更新时间并保存
          player.lastLogout = now
          savePlayer()
        
          // ✨ 埋点：记录由于上线产生的活跃
          RecordManager.shared.trackLogin(currentRealmName: getRealmShort())
      }
  
  
    // MARK: - Lifecycle
    func startGame() {
        startMainLoop()
    }
    
    func pauseGame() {
        mainLoopTimer?.invalidate()
        savePlayer()
    }
    
  
    // MARK: - Auto Gain
  
  // MARK: - 核心收益计算 (纯函数，不修改状态)
      
      /// 获取当前单次点击的真实收益 (包含 Buff 加成)
      /// ⚡ 纯计算函数，不修改任何状态，可安全在 View 中调用
    func getCurrentTapGain() -> Double {
      var gain = levelManager.tapGain(level: player.level, reincarnation: player.reincarnationCount)
      
      // 检查 Tap Buff (点击增益) - 只读取，不清理
      if let buff = player.tapBuff, Date() < buff.expireAt {
        gain *= (1.0 + buff.bonusRatio)
      }
      
      // 检查 Debuff - 只读取
      if let debuff = player.debuff, Date() < debuff.expireAt {
        gain *= debuff.multiplier
      }
      
      return gain
    }
    
    /// 计算当前的每秒收益 (带 Buff/Debuff 检查)
    /// ⚡ 纯计算函数，不修改任何状态，可安全在 View 中调用
    func getCurrentAutoGain() -> Double {
      var gain = levelManager.autoGain(level: player.level, reincarnation: player.reincarnationCount)
      
      // 检查 Auto Buff (增益) - 只读取
      if let buff = player.autoBuff, Date() < buff.expireAt {
        gain *= (1.0 + buff.bonusRatio)
      }
      
      // 检查 Debuff - 只读取
      if let debuff = player.debuff, Date() < debuff.expireAt {
        gain *= debuff.multiplier
      }
      
      return gain
    }
    
    /// 清理过期的 Buff/Debuff，在 tick() 中调用
    private func cleanupExpiredBuffs() {
      let now = Date()
      if let buff = player.tapBuff, buff.expireAt <= now {
        player.tapBuff = nil
      }
      if let buff = player.autoBuff, buff.expireAt <= now {
        player.autoBuff = nil
      }
      if let debuff = player.debuff, debuff.expireAt <= now {
        player.debuff = nil
      }
    }
    
    // MARK: - ⚡ 性能优化：统一主循环
    // 合并原先的 3 个定时器：自动收益 + 事件检测 + 自动保存
    // 现在：单个 1 秒定时器，内部通过计数器控制不同功能的执行频率
    private func startMainLoop() {
        mainLoopTimer?.invalidate()
        mainLoopTickCount = 0
        
        // ⚡ 修复：主循环始终运行，不受 autoGainEnabled 开关影响
        // autoGainEnabled 只控制自动收益，不影响事件检测和自动保存
        mainLoopTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.mainLoopTickCount += 1
            
            // 1. 自动收益（每 1 秒）- 仅当开关开启时执行
            if self.player.settings.autoGainEnabled {
                self.tick(deltaSeconds: 1.0)
            }
            
            // 2. 事件检测（每 10 秒 = 10 个 tick）
            if self.mainLoopTickCount % 10 == 0 {
                self.checkForEvent()
            }
            
            // 3. 自动保存（每 60 秒 = 60 个 tick）
            if self.mainLoopTickCount % 60 == 0 {
                print("⚡ MainLoop AutoSave", Date(), self.player.currentQi)
                self.savePlayer(forceSyncToPhone: false)
            }
        }
    }
    
    private func tick(deltaSeconds: Double) {
      // ✅ 修正：满级后停止数值计算 (已超脱)
      guard player.level < GameConstants.MAX_LEVEL else { return }
      
      // 如果在大结局回顾页面，也暂停计算
      guard !showEndgame else { return }
      
        let gain = getCurrentAutoGain() * deltaSeconds
        player.currentQi += gain
        checkBreakCondition()
      
        // ⚡ 在 tick 中统一清理过期的 Buff/Debuff
        cleanupExpiredBuffs()
    }
    
    // MARK: - Tap Action
    func onTap() {
      
        // ✅ 修正：满级后点击不再增加灵气
        guard player.level < GameConstants.MAX_LEVEL else { return }
      
        let gain = getCurrentTapGain()
  
        player.currentQi += gain
        player.click += 1
        HapticManager.shared.playIfEnabled(.click)

        
        checkBreakCondition()
    }
    
    // MARK: - Breakthrough
    
    /// 请求开始突破
    /// - Parameter onStart: 如果允许突破（无付费墙拦截），则执行此闭包
    func requestBreakthrough(onStart: () -> Void) {
        if player.level >= SkyConstants.FREE_MAX_LEVEL && !PurchaseManager.shared.hasAccess {
            // 拦截：显示付费墙
            self.showPaywall = true
        } else {
            // 放行：执行UI跳转
            onStart()
        }
    }
    
    var currentBreakSuccessRate: Double {
        levelManager.breakSuccess(level: player.level)
    }
    
    var isMajorBreakthrough: Bool {
        player.level % 9 == 0
    }
    
    /// 根据当前突破场景决定是否展示护身符商业化提示
    /// 规则：
    /// 1. 首次教学延后到胎息一层（19级）
    /// 2. 只对普通小层突破生效，不打断大境界小游戏
    /// 3. 成功率进入中后期风险区后，每个 9 级区间最多提醒一次
    func consumeCharmUpsellPrompt() -> CharmUpsellPrompt? {
        guard player.items.protectCharm == 0 else { return nil }
        guard !isMajorBreakthrough else { return nil }
        
        // 首次教学延后到胎息一层（19级）之后，避免前期过早打断
        if !player.hasSeenCharmIntro && player.level >= 19 {
            player.hasSeenCharmIntro = true
            savePlayer(forceSyncToPhone: false)
            return .intro
        }
        
        // 常规提醒只在成功率进入中后期风险区后才触发
        guard currentBreakSuccessRate <= 0.80 else { return nil }
        
        // 以 9 级为一个桶，每个区间最多提醒一次
        let bucket = (player.level - 1) / 9
        guard !player.charmPromptBuckets.contains(bucket) else { return nil }
        
        player.charmPromptBuckets.append(bucket)
        savePlayer(forceSyncToPhone: false)
        return .reminder
    }
    
    /// 发放当前端购买成功的消耗品库存
    /// 注意：护身符暂不跨端共享，因此 watch / iPhone 只增加各自本地库存
    func grantPurchasedConsumable(kind: ConsumableKind, quantity: Int) {
        switch kind {
        case .protectCharm:
            // 护身符库存只加到当前端，不做跨端共享
            player.items.protectCharm += quantity
            offlineToastMessage = String(
                format: NSLocalizedString("shop_purchase_success_format", comment: ""),
                quantity
            )
        }
        
        #if os(watchOS)
        savePlayer(forceSyncToPhone: false)
        #else
        savePlayer()
        #endif
    }

    private func checkBreakCondition() {
        let cost = levelManager.breakCost(level: player.level)
        showBreakButton = player.currentQi >= cost && player.level < GameConstants.MAX_LEVEL
    }
    
    func attemptBreak() -> Bool {
        guard showBreakButton else { return false }
        
        let successRate = levelManager.breakSuccess(level: player.level)
        let isPitySuccess = player.consecutiveBreakFailures >= 3
        let roll = Double.random(in: 0...1)
        let previousLevel = player.level
        let cost = levelManager.breakCost(level: previousLevel)
        
        if isPitySuccess || roll <= successRate {
          
            // ✨ 埋点：记录突破行为
            let effectiveRate = isPitySuccess ? 1.0 : successRate
            RecordManager.shared.trackBreak(success: true, successRate: effectiveRate, currentRealmName: getRealmShort())
        
            // Success
            player.level += 1
            player.currentQi = max(0, player.currentQi - cost)
            player.consecutiveBreakFailures = 0
            if isPitySuccess {
              DispatchQueue.main.async {
                self.offlineToastMessage = NSLocalizedString("watch_toast_pity_success", comment: "")
              }
            }
            
            // 成功消除所有 Debuff
            showBreakButton = false
            player.debuff = nil
          
            HapticManager.shared.playIfEnabled(.success)
            player.lastLogout = Date()
            savePlayer()
            return true
        } else {
          
          // ✨ 1. 记录累计失败次数 (无论是否有护身符，只要判定输了就算)
          // 或者你可以决定：用了护身符不算失败成就？通常算比较好，因为你确实脸黑。
          player.totalFailures += 1
          player.consecutiveBreakFailures += 1
          
          RecordManager.shared.trackBreak(success: false, successRate: successRate, currentRealmName: getRealmShort())
          
          
          if player.items.protectCharm > 0 {
            // --- 消耗护身符抵消惩罚 ---
            player.items.protectCharm -= 1
            
            // 提示用户
            DispatchQueue.main.async {
              self.offlineToastMessage = NSLocalizedString("watch_toast_charm_broken", comment: "")
            }
            
            // 必须在此处执行保存并返回 false
            HapticManager.shared.playIfEnabled(.failure) // 依然是失败震动
            checkBreakCondition()
            player.lastLogout = Date()
            savePlayer()
            return false // 👈 关键：界面会显示“突破失败”，但数值没掉
            
          } else {
            
            // Failure: lose 10% qi
            let penaltyRate = levelManager.breakFailPenalty(level: player.level)
            
            // 2. 执行扣除
            // 比如 penaltyRate 是 0.2 (20%)，那么剩余就是 0.8
            player.currentQi *= (1.0 - penaltyRate)
            
            
            if player.level >= 90 && player.debuff == nil {
              // 1小时内，自动收益降为 70%
              let expireDate = Date().addingTimeInterval(3600)
              player.debuff = DebuffStatus(type: .unstableDao, multiplier: 0.7, expireAt: expireDate)
              
              // 弹窗提示 (用 Toast)
              DispatchQueue.main.async {
                self.offlineToastMessage = NSLocalizedString("watch_toast_debuff_one_hour", comment: "")
              }
            }
            
            HapticManager.shared.playIfEnabled(.failure)
            
            checkBreakCondition()
            savePlayer()
            return false
          }
          
        }
    }
  
    func checkFeiSheng() {
      // ✨ 埋点：检查是否满级飞升
      if self.isAscended {
        RecordManager.shared.trackAscension()
        // 触发满级视图逻辑 (Show LifeReviewView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
          self.showEndgame = true
          self.showEventView = false
        }
        
      }
    }
    
    // MARK: - Event System
    // ⚡ 性能优化：startEventCheck 已被合并到 startMainLoop 中
    // 保留 checkForEvent() 方法供 mainLoop 调用
    
    private func checkForEvent() {
       // ✅ 修正：如果已经在大结局，或者当前正在显示事件，都不要触发
        guard !showEventView, !showEndgame else { return }
        
        // ⚡ 修复：只有 App 处于活跃状态时才弹出事件，避免息屏时 sheet 交互失效
        guard isAppActive else { return }
        
        // 也可以加一个双重保险：如果已经满级了，也不触发
        guard player.level < GameConstants.MAX_LEVEL else { return }
      
        let roll = Double.random(in: 0...1)
      
        // ✅ 修改这里：获取动态概率
        let currentProb = levelManager.getEventProbability(level: player.level,
                                                           reincarnation: player.reincarnationCount)
              
        if roll <= currentProb {
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
      
        // 判断是否是“接受/积极”的选项
        // 简单判断：如果 effect 是 nothing，通常是拒绝/离开
        // 或者在 JSON 里加个字段标记。
        // 这里用简单逻辑：只要不是 .nothing 就算接受
        let isAccepted = choice.effect.type != .nothing
        
        // ✨ 埋点：记录奇遇
        RecordManager.shared.trackEvent(accepted: isAccepted)
      
        applyEventEffect(choice.effect)
        showEventView = false
        currentEvent = nil
    }

    private func applyEventEffect(_ effect: EventEffect) {
      switch effect.type {
        
      case .gamble:
        // 博弈逻辑：
        // value 是基准值。
        // 赢了：获得 value * 1.5 ~ 2.0
        // 输了：扣除 value * 0.5 ~ 1.0
        
        guard let baseValue = effect.value else { return }
        
        // 1. 判定概率 (基础胜率 50%)
        // 进阶：境界越高，对低级事件的胜率越高
        let isWin = Double.random(in: 0...1) < 0.5
        
        if isWin {
          // 🎉 赌赢了！(暴击 1.5倍)
          let gain = baseValue * 1.5
          player.currentQi += gain
          
          // 成功震动
          HapticManager.shared.playIfEnabled(.success)

          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_gamble_win_format", comment: ""),
              Double(gain).xiuxianString
            )
          }
        } else {
          // 💀 赌输了！(扣除 50%)
            let loss = baseValue * 0.5
            player.currentQi = max(0, player.currentQi - loss)
            
            // 失败震动
            HapticManager.shared.playIfEnabled(.failure)
            
            DispatchQueue.main.async {
              self.offlineToastMessage = String(
                format: NSLocalizedString("watch_toast_gamble_lose_format", comment: ""),
                Double(loss).xiuxianString
              )
            }
          
        }
        
      case .gambleTap:
        guard let val = effect.value, let duration = effect.duration else { return }
        
        // 判定概率
        let isWin = Double.random(in: 0...1) < 0.5
        let expireDate = Date().addingTimeInterval(duration)
        
        if isWin {
          // 🎉 药效吸收成功：获得双倍效果 (或者按配置)
          // 比如配置是 1.0 (翻倍)，这里直接给
          player.tapBuff = BuffStatus(bonusRatio: val, expireAt: expireDate)
          
          HapticManager.shared.playIfEnabled(.success)
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_tap_boost_format", comment: ""),
              Int(duration)
            )
          }
        } else {
          // 💀 药力反噬：获得负面效果
          // 变成 -50% (减半)
          player.tapBuff = BuffStatus(bonusRatio: -0.5, expireAt: expireDate)
          
          HapticManager.shared.playIfEnabled(.failure)
          DispatchQueue.main.async {
            self.offlineToastMessage = NSLocalizedString("watch_toast_tap_debuff", comment: "")
          }
        }
        
        // MARK: - ✨ 赌自动修炼 (顿悟/走火入魔)
      case .gambleAuto:
        guard let val = effect.value, let duration = effect.duration else { return }
        
        let isWin = Double.random(in: 0...1) < 0.5
        let expireDate = Date().addingTimeInterval(duration)
        
        if isWin {
          // 🎉 顿悟成功
          player.autoBuff = BuffStatus(bonusRatio: val, expireAt: expireDate)
          
          HapticManager.shared.playIfEnabled(.success)
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_auto_boost_format", comment: ""),
              Int(duration)
            )
          }
        } else {
          // 💀 走火入魔 (直接上 Debuff)
          // 这里我们复用已有的 debuff 系统，或者给 autoBuff 一个负值
          player.debuff = DebuffStatus(type: .unstableDao, multiplier: 0.5, expireAt: expireDate)
          
          HapticManager.shared.playIfEnabled(.failure)
          DispatchQueue.main.async {
            self.offlineToastMessage = NSLocalizedString("watch_toast_auto_debuff", comment: "")
          }
        }
        
      case .gainQi:
        if let value = effect.value {
          player.currentQi += value
          // ✨ 新增：设置 Toast 消息，回到主页时自动弹出
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_event_gain_format", comment: ""),
              Double(value).xiuxianString
            )
          }
        }
      case .loseQi:
        if let value = effect.value {
          player.currentQi = max(0, player.currentQi - value)
          // ✨ 新增：扣除提示
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_event_lose_format", comment: ""),
              Double(value).xiuxianString
            )
          }
        }
      case .grantItem:
        player.items.protectCharm += 1
        // ✨ 新增：获得道具提示
        DispatchQueue.main.async {
          self.offlineToastMessage = NSLocalizedString("watch_toast_gain_charm", comment: "")
        }
      case .gainTapRatioTemp:
        // 逻辑处理：点击增益 (智能叠加)
        if let val = effect.value, let duration = effect.duration {
          var newExpireDate = Date().addingTimeInterval(duration)
          var newBonus = val
          
          // 🔥 检查是否已有生效的 Buff
          if let oldBuff = player.tapBuff, Date() < oldBuff.expireAt {
            // 1. 时间叠加：剩余时间 + 新时间
            let remainingTime = oldBuff.expireAt.timeIntervalSinceNow
            newExpireDate = Date().addingTimeInterval(remainingTime + duration)
            
            // 2. 数值取优：保留倍率更高的那个 (防止高级Buff被低级顶替)
            newBonus = max(oldBuff.bonusRatio, val)
          }
          
          // 应用更新
          player.tapBuff = BuffStatus(bonusRatio: newBonus, expireAt: newExpireDate)
          
          // 提示文案
          let totalDuration = newExpireDate.timeIntervalSinceNow
          let timeStr = formatDuration(totalDuration)
          let percent = Int(newBonus * 100)
          
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_tap_buff_extend_format", comment: ""),
              percent,
              timeStr
            )
          }
        }
        
      case .gainAutoTemp:
        // 逻辑处理：自动增益 (智能叠加)
        if let val = effect.value, let duration = effect.duration {
          var newExpireDate = Date().addingTimeInterval(duration)
          var newBonus = val
          
          // 🔥 检查是否已有生效的 Buff
          if let oldBuff = player.autoBuff, Date() < oldBuff.expireAt {
            // 1. 时间叠加
            let remainingTime = oldBuff.expireAt.timeIntervalSinceNow
            newExpireDate = Date().addingTimeInterval(remainingTime + duration)
            
            // 2. 数值取优
            newBonus = max(oldBuff.bonusRatio, val)
          }
          
          // 应用更新
          player.autoBuff = BuffStatus(bonusRatio: newBonus, expireAt: newExpireDate)
          
          // 提示文案
          let totalDuration = newExpireDate.timeIntervalSinceNow
          let timeStr = formatDuration(totalDuration)
          let percent = Int(newBonus * 100)
          
          DispatchQueue.main.async {
            self.offlineToastMessage = String(
              format: NSLocalizedString("watch_toast_auto_buff_extend_format", comment: ""),
              percent,
              timeStr
            )
          }
        }
        
      case .nothing:
        break
      }
      
      checkBreakCondition()
      savePlayer()
    }
  
    // 辅助方法：格式化时间显示
    private func formatDuration(_ seconds: TimeInterval) -> String {
          if seconds < 60 {
              return String(format: NSLocalizedString("watch_duration_seconds_format", comment: ""), Int(seconds))
          } else {
              return String(format: NSLocalizedString("watch_duration_minutes_format", comment: ""), seconds / 60)
          }
      }
  
  
    // MARK: - Settings
    func toggleHaptic() {
        player.settings.hapticEnabled.toggle()
        savePlayer()
        
        // ✨ 同步状态
        HapticManager.shared.isEnabled = player.settings.hapticEnabled
        
        if player.settings.hapticEnabled {
             HapticManager.shared.play(.click)
        }
    }
    
    func toggleSound() {
        player.settings.soundEnabled.toggle()
        savePlayer()
    }
  
    func toggleAutoGain() {
        player.settings.autoGainEnabled.toggle()
        // ⚡ 主循环内部会检查 autoGainEnabled，无需重启定时器
        savePlayer()
    }
  
    // MARK: - Auto Breakthrough (VIP Feature)
    func toggleAutoBreakthrough(_ enabled: Bool) {
        player.settings.autoBreakthrough = enabled
        savePlayer()
        
        // ✨ 修改：开关只控制是否"启用连击模式"
        // 真正的触发逻辑移到 BreakthroughView 中，由玩家手动点击"立即突破"后的结果页驱动
        if enabled {
            print("🚀 自动冲关模式：已开启 (手动突破后自动连击)")
        } else {
            print("🛑 自动冲关模式：已关闭")
        }
    }
    
    // 助手方法：检查能否继续自动突破
    func canAutoBreakNext() -> Bool {
        // 1. 灵气检查
        let cost = levelManager.breakCost(level: player.level)
        if player.currentQi < cost { return false }
        
        // 2. 也是大境界关卡检查
        let gameType = levelManager.getTribulationGameType(for: player.level)
        if gameType != .none { return false }
        
        return true
    }
    
    // MARK: - 删档重置 (Hard Reset)
    func resetGame() {
      // 1. 停止当前的所有计时器 (防止旧逻辑干扰)
      mainLoopTimer?.invalidate()  // ⚡ 优化：使用统一主循环
      
      // 2. 重置玩家数据 (回到 0 世，Lv 1)
      // Player 的 init() 默认 reincarnationCount = 0
      self.player = Player()
      
      // 3. 🚨 关键：重置所有 UI 状态标志位
      self.showBreakButton = false
      self.currentEvent = nil
      self.showEventView = false
      self.showEndgame = false // 👈 必须设为 false，否则会卡在大结局界面
      self.offlineToastMessage = nil
      
      // 4. 🚨 关键：通知史官重置当前记录
      // 删档意味着“这一世白活了”，所以要清空当前的 Record
      RecordManager.shared.resetCurrentRecord()
      
      // 5. 重新启动游戏循环
      startGame()
      savePlayer()
      
      // 6. 震动反馈 (像是系统重启的感觉)
      HapticManager.shared.playIfEnabled(.directionDown)
    }
  
    
    // MARK: - Persistence
    // ⚡ 性能优化：setupAutoSave 已被合并到 startMainLoop 中
    // 自动保存现在每 60 秒执行一次（原先 30 秒）
    
    func savePlayer(forceSyncToPhone: Bool = true) {
        if let encoded = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(encoded, forKey: SkyConstants.UserDefaults.userDefaultsKey)
        }
      
        // 2. ✨ 保存 Widget 快照 (仅 Watch 端或者是共享容器支持时)
        // 获取当前等级的突破需求
        let cost = levelManager.breakCost(level: player.level)
        // 获取当前的基础自动产出 (含轮回加成)
        let rawGain = levelManager.autoGain(level: player.level, reincarnation: player.reincarnationCount)
        
        #if os(watchOS)
        SharedDataManager.saveSnapshot(
            player: player,
            breakCost: cost,
            rawAutoGain: rawGain,
            isUnlocked: PurchaseManager.shared.hasAccess // 🔥 传入解锁状态
        )
        #endif
      
        // 3. ✨ 发送数据到手机 (智能节流)
        // 仅 Watch 端才需要发送给手机
        #if os(watchOS)
        let now = Date()
        // 判定条件：强制发送 OR 距离上次发送超过 5 分钟 (300秒)
        if forceSyncToPhone || now.timeIntervalSince(lastPhoneSyncTime) > 300 {
          SkySyncManager.shared.sendDataToPhone(player: self.player)
          lastPhoneSyncTime = now
          print("📡 同步手机成功 (强制: \(forceSyncToPhone))")
        }
        #endif

       //手机端上传GameCenter
        #if os(iOS)
      
        if player.level > 0 {
          print("WatchSync (iOS): processIncomingGameData submitScore",player.level)
          
          // ✅ 使用封装好的公式计算总分
          let totalScore = GameLevelManager.shared.calculateTotalScore(
            level: player.level,
            reincarnation: player.reincarnationCount
          )
          
          // 提交总胜利数到 Game Center 排行榜
          GameCenterManager.shared.submitScore(Int(totalScore), to: SkyConstants.GameCenter.Leaderboard.playerLevelIphone.rawValue)
        
        }
        
        if player.click > 0 {
          
          GameCenterManager.shared.submitScore(player.click, to: SkyConstants.GameCenter.Leaderboard.playerClickIphone.rawValue)

        }
    
        AchievementReporter.shared.checkAndReport(for: player)
  
        #endif
      
    }
    
    // MARK: - Getters
    func getCurrentProgress() -> Double {
        return levelManager.progress(currentQi: player.currentQi, level: player.level)
    }
  
    // 获取完整描述 (用于设置页等)
    func getCurrentRealm() -> String {
       return levelManager.realmDescription(for: player.level,reincarnation: player.reincarnationCount)
    }
    // 获取短描述 (用于主页大标题)
    func getRealmShort() -> String {
       return levelManager.stageName(for: player.level,reincarnation: player.reincarnationCount)
    }
  
    // 获取层级 (用于主页胶囊)
    func getLayerName() -> String {
        return levelManager.layerName(for: player.level)
    }
    
    // ✨ 触发炼化动画
    func triggerRefineAnimation(amount: Double) {
        self.refineEvent = RefineEvent(amount: amount)
    }

  
}

extension GameManager {
  // MARK: - 小游戏结算逻辑 (与概率突破逻辑保持一致)
      func finalizeMiniGame(isWin: Bool) -> Bool {
          let cost = levelManager.breakCost(level: player.level)
          // 为了统计数据，我们需要获取当前的理论成功率
          let successRate = levelManager.breakSuccess(level: player.level)
          
          if isWin {
              // 🎉 --- 渡劫成功 ---
              
              // 1. 埋点 (成功)
              RecordManager.shared.trackBreak(success: true, successRate: successRate, currentRealmName: getRealmShort())
              
              // 2. 检查飞升 (如果是满级前的最后一次渡劫)
              if player.level >= GameConstants.MAX_LEVEL {
                  RecordManager.shared.trackAscension()
                  // 延迟触发大结局 UI
                  DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                      self.showEndgame = true
                  }
              }
              
              // 3. 执行升级
              player.level += 1
              player.currentQi = max(0, player.currentQi - cost)
              
              // 4. 清除负面状态
              player.debuff = nil
              showBreakButton = false
              
              HapticManager.shared.playIfEnabled(.success)
              savePlayer()
              return true
              
          } else {
              // 💔 --- 渡劫失败 ---
              
              // 1. 埋点 (失败)
              RecordManager.shared.trackBreak(success: false, successRate: successRate, currentRealmName: getRealmShort())
              
              // 2. ✨ 检查护身符 (保持逻辑一致性：手残也能用道具救)
              if player.items.protectCharm > 0 {
                  player.items.protectCharm -= 1
                  
                  DispatchQueue.main.async {
                      self.offlineToastMessage = NSLocalizedString("watch_toast_break_fail_charm", comment: "")
                  }
                  
                  // 仅震动，不扣灵气
                  HapticManager.shared.playIfEnabled(.failure)
                  checkBreakCondition()
                  savePlayer()
                  return false
                  
              } else {
                  // 3. 💀 执行惩罚 (复用 breakFailPenalty 公式)
                  
                  // 获取当前等级对应的惩罚比例 (例如 10% - 30%)
                  let penaltyRate = levelManager.breakFailPenalty(level: player.level)
                  let lostQi = player.currentQi * penaltyRate
                  
                  // 扣除灵气
                  player.currentQi -= lostQi
                  
                  // 4. 高境界 Debuff (道心不稳)
                  if player.level >= 90 {
                      let expireDate = Date().addingTimeInterval(3600)
                      player.debuff = DebuffStatus(type: .unstableDao, multiplier: 0.7, expireAt: expireDate)
                      
                      DispatchQueue.main.async {
                          self.offlineToastMessage = String(
                            format: NSLocalizedString("watch_toast_break_fail_debuff_format", comment: ""),
                            lostQi.xiuxianString
                          )
                      }
                  } else {
                      // 普通提示
                      DispatchQueue.main.async {
                          self.offlineToastMessage = String(
                            format: NSLocalizedString("watch_toast_break_fail_normal_format", comment: ""),
                            lostQi.xiuxianString
                          )
                      }
                  }
                  
                  HapticManager.shared.playIfEnabled(.failure)
                  checkBreakCondition()
                  savePlayer()
                  return false
              }
          }
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

extension GameManager {
  
  /// 方案 A: 合上札记 (进入观想模式)
     func enterZenMode() {
         // 只需要关闭大结局视图，回到主页
         // 因为等级已经是 MAX，MainView 会自动变为观想形态 (稍后适配)
         self.showEndgame = false
         // ⚡ 优化：停止主循环省电
         self.mainLoopTimer?.invalidate()
     }
     
     /// 方案 B: 转世重修 (删号重练)
     func reincarnate() {
         // 1. 史官封存记录
         RecordManager.shared.reincarnate()
         
         // 2. 重置玩家数值 (保留 ID 和 设置)
         let oldSettings = player.settings
         let oldId = player.id
         let nextCount = player.reincarnationCount + 1
         let savedClicks = player.click // 点击数也要保留！
         let savedFailures = player.totalFailures // ✨ 失败数也要保留！
       
       
         self.player = Player() // 重新初始化
         self.player.id = oldId
         self.player.settings = oldSettings // 继承设置
         // ✨ 继承轮回次数
         self.player.reincarnationCount = nextCount
         self.player.click = savedClicks         // ✅ 继承点击
         self.player.totalFailures = savedFailures // ✅ 继承失败
       
       
         // 3. 状态重置
         self.showEndgame = false
         self.currentEvent = nil
         self.showEventView = false
         self.showBreakButton = false
      
       
         // 4. 重新启动循环
         startGame()
         savePlayer()
         
         // 5. 反馈
         HapticManager.shared.playIfEnabled(.success)
     }
  
}
