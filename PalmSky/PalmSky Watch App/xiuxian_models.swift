import Foundation
import SwiftUI

// MARK: - Game Constants
struct GameConstants {
    // Gameplay tuning
    // 基础收益
    static let BASE_GAIN = 5.0
    static let AUTO_GAIN_RATIO = 0.30
  
   // 成长曲线
    static let STAGE_POWER = 1.25         // 境界倍率
    static let FLOOR_STEP_RATIO = 0.05    // 层次增长
    static let BREAK_COST_BASE = 50.0
    static let BREAK_COST_FACTOR = 1.15     // 消耗指数
  
    // 成功率
    static let BREAK_SUCCESS_LOWER = 0.6
    static let BREAK_SUCCESS_DECAY_PER_LEVEL = 0.0023
    
    // Event / Frequency
    static let EVENT_CHECK_INTERVAL_SECONDS = 10.0
    static let EVENT_PROBABILITY_PER_CHECK = 0.025
    
    // Complication
    static let COMPLICATION_REFRESH_MINUTES = 30
    static let COMPLICATION_ALERT_THRESHOLD_PCT = 0.90
    
    // 16 大境界
    static let stageNames = [
        "筑基", "开光", "胎息", "辟谷", "金丹", "元婴", "出窍", "分神",
        "合体", "大乘", "渡劫", "地仙", "天仙", "金仙", "大罗金仙", "九天玄仙"
    ]
    
  // 中文数字映射 (用于层级显示)
    static let cnNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
  
    static let MAX_LEVEL = 144
}

// MARK: - Player Model
struct Player: Codable {
    var id: String
    var level: Int
    var currentQi: Double
    var lastLogout: Date
    var settings: Settings
    var items: Items
    
    init(id: String = "default_player") {
        self.id = id
        self.level = 1
        self.currentQi = 0.0
        self.lastLogout = Date()
        self.settings = Settings()
        self.items = Items()
    }
}

struct Settings: Codable {
    var hapticEnabled: Bool = true
    var autoGainEnabled: Bool = true
}

struct Items: Codable {
    var protectCharm: Int = 0
}

// MARK: - Event Models
struct GameEvent: Codable, Identifiable {
    let id: String
    let title: String
    let desc: String
    let choices: [EventChoice]
    let rarity: String?
}

struct EventChoice: Codable, Identifiable {
    let id: String
    let text: String
    let effect: EventEffect
}

struct EventEffect: Codable {
    let type: EffectType
    let value: Double?
    
    enum EffectType: String, Codable {
        case gainQi = "gain_qi"
        case gainTapRatioTemp = "gain_tap_ratio_temp"
        case gainAutoTemp = "gain_auto_temp"
        case loseQi = "lose_qi"
        case grantItem = "grant_item"
        case nothing = "nothing"
    }
}

// MARK: - Game Level Manager
class GameLevelManager {
    static let shared = GameLevelManager()
    private init() {}
    
    let baseGain = GameConstants.BASE_GAIN
    let autoRatio = GameConstants.AUTO_GAIN_RATIO
    let stageFactor = GameConstants.STAGE_POWER
    let floorStep = GameConstants.FLOOR_STEP_RATIO
    let breakBase = GameConstants.BREAK_COST_BASE
    let breakFactor = GameConstants.BREAK_COST_FACTOR
    let breakLower = GameConstants.BREAK_SUCCESS_LOWER
    let breakDecay = GameConstants.BREAK_SUCCESS_DECAY_PER_LEVEL
    
    // Calculate stage index (0-15)
    func stage(for level: Int) -> Int {
        return (level - 1) / 9
    }
    
    // Calculate floor within stage (1-9)
    func floor(for level: Int) -> Int {
        return ((level - 1) % 9) + 1
    }
    
    // Get stage name
    func stageName(for level: Int) -> String {
        let idx = stage(for: level)
        guard idx >= 0 && idx < GameConstants.stageNames.count else {
            return "未知境界"
        }
        return GameConstants.stageNames[idx]
    }
    
    // 获取中文层级 (例如: "五层")
    func layerName(for level: Int) -> String {
        if level == 0 { return "" }
        let layerIndex = (level - 1) % 9
        let cnNumbers = GameConstants.cnNumbers
        if layerIndex < cnNumbers.count {
            return "\(cnNumbers[layerIndex])层"
        }
        return "\(layerIndex + 1)层"
    }
  
    // Get full realm description
    func realmDescription(for level: Int) -> String {
        let name = stageName(for: level)
        let floorNum = floor(for: level)
        return "\(name) 第\(floorNum)层"
    }
    
    // Calculate tap gain
    func tapGain(level: Int) -> Double {
        let s = Double(stage(for: level))
        let f = Double(floor(for: level))
        let stageMultiplier = pow(stageFactor, s)
        let floorMultiplier = 1.0 + floorStep * (f - 1.0)
        return baseGain * stageMultiplier * floorMultiplier
    }
    
    // Calculate auto gain per second
    func autoGain(level: Int) -> Double {
        return tapGain(level: level) * autoRatio
    }
    
    // Calculate qi required for breakthrough
    func breakCost(level: Int) -> Double {
        return breakBase * pow(breakFactor, Double(level))
    }
    
    // Calculate breakthrough success rate
    func breakSuccess(level: Int) -> Double {
        let v = 0.95 - Double(level) * breakDecay
        return max(breakLower, v)
    }
    
    // Progress percentage for current level
    func progress(currentQi: Double, level: Int) -> Double {
        let cost = breakCost(level: level)
        return min(currentQi / cost, 1.0)
    }
}
