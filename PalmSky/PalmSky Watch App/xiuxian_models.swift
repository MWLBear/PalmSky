import Foundation
import SwiftUI

// MARK: - Game Constants
struct GameConstants {
    // Gameplay tuning
    // 基础收益
   static let BASE_GAIN = 10.0       // 提高起步数值，让数字看起来更大气
   static let AUTO_GAIN_RATIO = 0.5  // 提高自动收益占比，护肝
  
    // 成长曲线 (指数爆炸模型)
    static let STAGE_POWER = 1.6            // 降低至 1.6 (压制数值膨胀)
    static let FLOOR_STEP_RATIO = 0.05      // 每层微调 5%
  
    static let BREAK_COST_BASE = 100.0
    static let BREAK_COST_FACTOR = 1.18    // 提升至 1.18 (难度核心)
  
    // 成功率
    static let BREAK_SUCCESS_LOWER = 0.6
    static let BREAK_SUCCESS_DECAY_PER_LEVEL = 0.0023
    
    // Event / Frequency
    static let EVENT_CHECK_INTERVAL_SECONDS = 10.0
    static let EVENT_PROBABILITY_PER_CHECK = 0.05   // 提高一点奇遇概率到 5%，增加乐趣
    
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
    var debuff: DebuffStatus?

    init(id: String = "default_player") {
        self.id = id
        self.level = 1
        self.currentQi = 0.0
        self.lastLogout = Date()
        self.settings = Settings()
        self.items = Items()
    }
}

// 单独定义的 Debuff 结构体
struct DebuffStatus: Codable {
    var type: DebuffType
    var multiplier: Double // 收益倍率 (例如 0.7)
    var expireAt: Date     // 过期时间
    
    enum DebuffType: String, Codable {
        case unstableDao // 道心不稳
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
    
  // MARK: - 核心产出公式 (修正版)
    func tapGain(level: Int) -> Double {
        // 1. 计算大境界索引 (0, 1, 2 ... 15)
        // Level 1-9 -> 0 (筑基)
        // Level 10-18 -> 1 (开光)
        let stageIndex = Double((level - 1) / 9)
        
        // 2. 计算小层级 (1 ... 9)
        let floorLevel = Double(((level - 1) % 9) + 1)
        
        // 3. ⚠️ 修正点：STAGE_POWER 只作用于 stageIndex
        // 这样前期 (stage=0) 倍率是 1.0，不会因为底数 1.6 太小而导致收益过低
        let stageMultiplier = pow(GameConstants.STAGE_POWER, stageIndex)
        
        // 4. 小层级增长 (线性)
        // 每一层微涨 5% (1.0, 1.05, 1.10 ... 1.40)
        let floorMultiplier = 1.0 + GameConstants.FLOOR_STEP_RATIO * (floorLevel - 1.0)
        
        // 最终公式
        return GameConstants.BASE_GAIN * stageMultiplier * floorMultiplier
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
  
  
    // MARK: - 失败惩罚计算 (高级动态版)
    func breakFailPenalty(level: Int) -> Double {
      // 1. 基础线性增长惩罚 (10% -> 30%)
      let basePenalty = 0.10
      let scaling = (Double(level) / Double(GameConstants.MAX_LEVEL)) * 0.20
      let rawPenalty = min(basePenalty + scaling, 0.35)
      
      // 2. 🛡️ 软化机制：成功率越低，惩罚越轻
      // 防止 "难上加难" 劝退玩家
      let successRate = breakSuccess(level: level)
      
      // 如果成功率只有 50%，softenFactor = 1 - (0.3 * 0.5) = 0.85 (惩罚打85折)
      // 系数 0.3 可调：越大，对低胜率玩家越仁慈
      let softenFactor = 1.0 - (0.3 * (1.0 - successRate))
      
      return rawPenalty * softenFactor
    }
    
  
}
