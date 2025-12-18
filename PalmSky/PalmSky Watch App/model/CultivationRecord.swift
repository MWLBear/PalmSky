//
//  CultivationRecord.swift
//  PalmSky Watch App
//
//  Created by mac on 12/15/25.
//

import Foundation

struct CultivationRecord: Codable {
    // MARK: - 时间刻度
    var startDate: Date             // 入道时间 (第一次玩的时间)
    var finishDate: Date?           // 飞升时间 (满级时间)
    var lastLoginDate: Date         // 最后活跃时间 (用于计算总天数)
    
    // MARK: - 苦难与坚持 (Struggles)
    var breakAttempts: Int = 0      // 尝试突破总次数
    var breakFailures: Int = 0      // 失败总次数
  // 🔴 补上这个漏掉的属性
    var breakSuccesses: Int = 0     // 成功突破次数
  
    // 停滞记录 (用于生成："你曾在元婴期停留了41天")
    var lastBreakDate: Date         // 上一次突破成功的时间
    var longestStagnation: TimeInterval = 0 // 最长卡关时间 (秒)
    
    // ✨ 新增：记录卡关时的境界名 (例如 "元婴")
    var longestStagnationStageName: String?
  
    // MARK: - 选择与机缘 (Choices)
    var eventsTriggered: Int = 0    // 遇到奇遇次数
    var eventsAccepted: Int = 0     // 接受/冒险次数
    var eventsRejected: Int = 0     // 放弃/稳健次数
    
    // MARK: - 性格画像 (Personality)
    // 记录玩家是在高概率时才动，还是低概率时就赌
    var riskyBreakCount: Int = 0    // 险中求胜次数 (成功率<60%仍尝试)
    var steadyBreakCount: Int = 0   // 稳扎稳打次数 (成功率>90%才尝试)
    
    // 初始化
    init() {
        self.startDate = Date()
        self.lastLoginDate = Date()
        self.lastBreakDate = Date()
    }
    
    // 计算总修仙天数
    var totalDays: Int {
        let end = finishDate ?? Date()
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: end)
        return max(1, diff.day ?? 1)
    }
    
    // 计算最长停滞天数
    var maxStagnationDays: Int {
        return Int(longestStagnation / 86400)
    }
}
