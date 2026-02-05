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
  //  static let EVENT_PROBABILITY_PER_CHECK = 0.05   // 提高一点奇遇概率到 5%，增加乐趣
    
    // ✅ 新增：基础概率与成长系数
    static let EVENT_PROB_BASE = 0.08       // 基础 5%
    static let EVENT_PROB_MAX = 0.10        // 上限 10% (太高会很烦)
  
    // Complication
    static let COMPLICATION_REFRESH_MINUTES = 30
    static let COMPLICATION_ALERT_THRESHOLD_PCT = 0.90
    
    // 16 大境界
    static let stageNames = [
        "筑基", "开光", "胎息", "辟谷", "金丹", "元婴", "出窍", "分神",
        "合体", "大乘", "渡劫", "地仙", "天仙", "金仙", "大罗金仙", "九天玄仙"
    ]
  
    // 轮回前缀 (0-9世)
    static let zhuanNames = [
      "",       // 第1世 (reincarnation = 0)
      "真",     // 第2世 (reincarnation = 1)
      "玄",     // 第3世
      "灵",     // 第4世
      "妙",     // 第5世
      "元",     // 第6世
      "太",     // 第7世
      "上",     // 第8世
      "至",     // 第9世
      "道"      // 第10世+
    ]
        
  // 中文数字映射 (用于层级显示)
    static let cnNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
  
    static let MAX_LEVEL = 144
}

// MARK: - Player Model
struct Player: Codable {
    var id: String
    var level: Int
    var click: Int
    var currentQi: Double
    var lastLogout: Date
    var settings: Settings
    var items: Items
    var debuff: DebuffStatus?

    // ✨ 新增：增益状态
    var tapBuff: BuffStatus?  // 点击增益
    var autoBuff: BuffStatus? // 自动修炼增益
  
   // ✨ 新增：轮回次数 (第1世是0，转世后变成1)
    var reincarnationCount: Int = 0
   // ✨ 新增：累计失败次数 (用于成就)
    var totalFailures: Int = 0
    // ✨ 连续突破失败次数 (保底机制)
    var consecutiveBreakFailures: Int = 0
    
    // 🚨 必须手动添加 CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, level, click, currentQi, lastLogout, settings, items, debuff
        case tapBuff, autoBuff, reincarnationCount, totalFailures, consecutiveBreakFailures
    }
  
    init(id: String = "default_player") {
        self.id = id
        self.level = 1
        self.click = 0
        self.currentQi = 0.0
        self.totalFailures = 0
        self.consecutiveBreakFailures = 0
        self.lastLogout = Date()
        self.settings = Settings()
        self.items = Items()
    }
    
    // ✨ 安全解码构造函数
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        level = try container.decode(Int.self, forKey: .level)
        click = try container.decode(Int.self, forKey: .click)
        currentQi = try container.decode(Double.self, forKey: .currentQi)
        lastLogout = try container.decode(Date.self, forKey: .lastLogout)
        settings = try container.decode(Settings.self, forKey: .settings)
        items = try container.decode(Items.self, forKey: .items)
        
        // Optionals are safe with decodeIfPresent
        debuff = try container.decodeIfPresent(DebuffStatus.self, forKey: .debuff)
        tapBuff = try container.decodeIfPresent(BuffStatus.self, forKey: .tapBuff)
        autoBuff = try container.decodeIfPresent(BuffStatus.self, forKey: .autoBuff)
        
        // ✨ 新增字段：给予默认值，防删档
        reincarnationCount = try container.decodeIfPresent(Int.self, forKey: .reincarnationCount) ?? 0
        totalFailures = try container.decodeIfPresent(Int.self, forKey: .totalFailures) ?? 0
        consecutiveBreakFailures = try container.decodeIfPresent(Int.self, forKey: .consecutiveBreakFailures) ?? 0
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

// 1. 定义 Buff 状态结构
struct BuffStatus: Codable {
    var bonusRatio: Double // 增益比例 (例如 0.5 代表 +50%)
    var expireAt: Date     // 过期时间
}


struct Settings: Codable {
    var hapticEnabled: Bool = true
    var autoGainEnabled: Bool = true
    var soundEnabled: Bool = true
    
    // ✨ 新增：VIP 自动冲关
    var autoBreakthrough: Bool = false
    
    // 🚨 手动添加 CodingKeys
    enum CodingKeys: String, CodingKey {
        case hapticEnabled
        case autoGainEnabled
        case soundEnabled
        case autoBreakthrough
    }
    
    // ✨ 空构造函数
    init() {}
    
    // ✨ 安全解码构造函数 (防旧版本数据崩溃)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        hapticEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticEnabled) ?? true
        autoGainEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoGainEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        autoBreakthrough = try container.decodeIfPresent(Bool.self, forKey: .autoBreakthrough) ?? false
    }
}

//护身符（你已有）
//
//减少突破失败惩罚 / 抵消一次失败
//
//静心符（未来）
//
//离线收益 +10%（但上限不变）
//
//悟道符（后期）
//
//提高极小量成功率（+1~2%）

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
  
    // ✨ 新增：境界限制
    let minStage: String? // 例如 "筑基"
    let maxStage: String? // 例如 "金丹"
  
}

struct EventChoice: Codable, Identifiable {
    let id: String
    let text: String
    let effect: EventEffect
}

struct EventEffect: Codable {
    let type: EffectType
    let value: Double?
    let duration: TimeInterval?

    enum EffectType: String, Codable {
        case gainQi = "gain_qi"
        case loseQi = "lose_qi"

        case gainTapRatioTemp = "gain_tap_ratio_temp"
        case gainAutoTemp = "gain_auto_temp"
      
        case grantItem = "grant_item"
        case nothing = "nothing"
      
        // ✨ 新增：博弈 Buff (赌药效)
        case gambleTap = "gamble_tap"   // 赌点击倍率
        case gambleAuto = "gamble_auto" // 赌自动修炼
        case gamble = "gamble"       //赌灵气
      
    }
}
