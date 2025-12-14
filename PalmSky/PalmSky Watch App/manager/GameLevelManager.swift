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
//        let floorNum = floor(for: level)
//        return "\(name) 第\(floorNum)层"
    
        let floorNum = layerName(for: level)
        return "\(name) 第\(floorNum)"
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
