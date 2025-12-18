//
//  GameLevelManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/14/25.
//

import Foundation
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
    func stageName(for level: Int, reincarnation: Int = 0) -> String {
        let idx = stage(for: level)
        let baseName: String

        if idx >= 0 && idx < GameConstants.stageNames.count {
          baseName = GameConstants.stageNames[idx]
        } else {
          baseName = "未知境界"
        }
      
      // 2. ✨ 添加轮回前缀 (New)
      if reincarnation > 0 {
        // 前缀库：真、玄、灵、地、天、仙、神、圣、道、绝
        let prefixes = GameConstants.zhuanNames
        // 防止轮回次数超过数组长度，取最后一个
        let prefixIndex = min(reincarnation, prefixes.count - 1)
        return "\(prefixes[prefixIndex])·\(baseName)"
      }
      
      return baseName
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
  
   // ⚠️ 修改：增加 reincarnation 参数，默认为 0
    func realmDescription(for level: Int, reincarnation: Int = 0) -> String {
        let name = stageName(for: level, reincarnation: reincarnation)
        let floorNum = layerName(for: level)
        return "\(name) \(floorNum)"
    }
    
    // MARK: - 核心产出公式 (支持轮回加成)

    func tapGain(level: Int, reincarnation: Int) -> Double {
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
        
        let baseGain = GameConstants.BASE_GAIN * stageMultiplier * floorMultiplier

        // 4. ✨ 轮回加成 (New)
        // 每一世增加 20% 的全局收益 (第0世=1.0, 第1世=1.2, 第2世=1.4...)
        let reincarnationMultiplier = 1.0 + (Double(reincarnation) * 0.2)
        
        // 最终公式
        return baseGain * reincarnationMultiplier

    }
  
    
    // Calculate auto gain per second
    func autoGain(level: Int, reincarnation: Int) -> Double {
        return tapGain(level: level, reincarnation: reincarnation) * autoRatio
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
    
    //// ⚠️ 注意：事件概率是“打断节奏”的系统，所有加成都必须是“感觉增强 > 数值增强”
    // MARK: - 事件概率计算 (天机感应 + 轮回递减版)
      func getEventProbability(level: Int, reincarnation: Int) -> Double {
          // 1. 基础配置
          let base = GameConstants.EVENT_PROB_BASE // 0.05
          let maxLimit = GameConstants.EVENT_PROB_MAX // 0.10
          
          // 2. 进度曲线 (使用平方根 sqrt)
          // 效果：前期增长快(新手机缘多)，后期趋于平缓(大道至简)
          let rawProgress = Double(level) / Double(GameConstants.MAX_LEVEL)
          let curvedProgress = sqrt(rawProgress)
          
          var prob = base + (maxLimit - base) * curvedProgress
          
          // 3. 境界威压 (Stage Step)
          // 每突破一个大境界，对天地的感应微弱提升
          let stageIndex = Double((level - 1) / 9)
          let stageBonus = stageIndex * 0.001
          prob += stageBonus
          
          // 4. ✨ 轮回气运 (收益递减模型)
          // 逻辑：sqrt(轮回次数) * 0.005
          // 第1世: +0.5% (初次觉醒，造化最大)
          // 第4世: +1.0% (翻倍的轮回，才换来翻倍的气运)
          // 第9世: +1.5% (越往后，对天道的边际效应越低)
          let reincarnationBonus = sqrt(Double(reincarnation)) * 0.005
          prob += reincarnationBonus
          
          // 5. 天道封顶 (Hard Cap)
          // 无论几世轮回，事件频率最高锁死在 15%，留一片清净
          return min(prob, 0.15)
      }
  
}
