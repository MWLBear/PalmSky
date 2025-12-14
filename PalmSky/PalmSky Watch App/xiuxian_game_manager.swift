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
    private func startAutoGain() {
        timer?.invalidate()
        
        guard player.settings.autoGainEnabled else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick(deltaSeconds: 1.0)
        }
    }
    
    private func tick(deltaSeconds: Double) {
        let gain = levelManager.autoGain(level: player.level) * deltaSeconds
        player.currentQi += gain
        checkBreakCondition()
    }
    
    // MARK: - Tap Action
    func onTap() {
        let gain = levelManager.tapGain(level: player.level)
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
            player.currentQi *= 0.9
            
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
        if let event = EventPool.shared.randomEvent() {
            currentEvent = event
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
            }
        case .loseQi:
            if let value = effect.value {
                player.currentQi = max(0, player.currentQi - value)
            }
        case .grantItem:
            player.items.protectCharm += 1
        case .gainTapRatioTemp, .gainAutoTemp, .nothing:
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

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    enum HapticType {
        case light
        case success
        case error
    }
    
    func play(_ type: HapticType) {
        #if os(watchOS)
        switch type {
        case .light:
            WKInterfaceDevice.current().play(.click)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .error:
            WKInterfaceDevice.current().play(.failure)
        }
        #endif
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
