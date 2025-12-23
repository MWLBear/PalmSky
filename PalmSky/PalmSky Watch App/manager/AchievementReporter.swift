//
//  AchievementReporter.swift
//  PalmSky Watch App
//
//  Created by mac on 12/21/25.
//

import Foundation
import GameKit

class AchievementReporter {
    
    // 单例模式，方便调用
    static let shared = AchievementReporter()
    private init() {}
    
    /// 🔍 核心入口：检查并上报所有成就
    /// - Parameter player: 最新的玩家数据
    func checkAndReport(for player: Player) {
        
        // 1. 检查境界成就
        checkRealmAchievements(player: player)
        
        // 2. 检查点击成就
        checkClickAchievements(player: player)
        
        // 3. 检查轮回成就
        checkReincarnationAchievements(player: player)
        
      // ✨ 新增：检查失败成就
        checkFailureAchievements(player: player)
      
        print("✅ AchievementReporter: 成就检查完毕")
    }
    
    // MARK: - 内部逻辑分类
    
  
  // MARK: - 内部逻辑分类
      
      /// A. 境界类 (一次性解锁)
      /// 进入境界 → 给反馈
      ///走完境界 → 给成就
  
      private func checkRealmAchievements(player: Player) {
          // 定义境界目标映射表
          let realmTargets: [(level: Int, id: String)] = [
              (9,   SkyConstants.GameCenter.Achievement.realmFoundation),   // 筑基：入道
              (36,  SkyConstants.GameCenter.Achievement.realmPigu),         // 辟谷：脱凡
              (45,  SkyConstants.GameCenter.Achievement.realmCore),         // 金丹：质变
              (54,  SkyConstants.GameCenter.Achievement.realmNascent),      // 元婴：第二生命
              (72,  SkyConstants.GameCenter.Achievement.realmDemigod),      // 分神：道心外化
              (99,  SkyConstants.GameCenter.Achievement.realmTribulation),  // 渡劫：生死线
              (108, SkyConstants.GameCenter.Achievement.realmEarth),        // 地仙：超脱凡界
              (GameConstants.MAX_LEVEL, SkyConstants.GameCenter.Achievement.ascension) // 飞升：终章
          ]
          
          // 遍历检查
          for target in realmTargets {
              if player.level >= target.level {
                  submit(id: target.id, percent: 100)
              }
          }
      }
      
      /// B. 点击类 (进度累积型)
      private func checkClickAchievements(player: Player) {
          guard player.click > 0 else { return }
          
          // 定义点击目标映射表
          let tapTargets: [(count: Double, id: String)] = [
              (10_000,    SkyConstants.GameCenter.Achievement.tap10k),
              (50_000,    SkyConstants.GameCenter.Achievement.tap50k),
              (100_000,   SkyConstants.GameCenter.Achievement.tap100k),
              (1_000_000, SkyConstants.GameCenter.Achievement.tap1m)
          ]
          
          // 遍历检查所有点击成就
          for target in tapTargets {
              // 计算进度
              let percent = (Double(player.click) / target.count) * 100.0
              
              // 提交进度 (submit 内部会自动处理 cap 到 100 的逻辑)
              // GameKit 会自动处理“如果这次提交的百分比比上次低则忽略”，所以放心循环提交
              submit(id: target.id, percent: percent)
          }
      }
  
    /// C. 轮回类
    private func checkReincarnationAchievements(player: Player) {
        // 再活一世
        if player.reincarnationCount >= 1 {
            submit(id: SkyConstants.GameCenter.Achievement.reincarnation1, percent: 100)
        }
    }
    
    /// D. 失败类 (累计型)
     private func checkFailureAchievements(player: Player) {
         guard player.totalFailures > 0 else { return }
         
         // 1. 道心稳固 (失败 10次)
         // 这是一个早期安慰奖
         if player.totalFailures >= 10 {
             submit(id: SkyConstants.GameCenter.Achievement.fail10, percent: 100)
         }
         
         // 2. 百折不挠 (失败 50次)
         // 这是一个进度成就
         let target = 50.0
         let percent = (Double(player.totalFailures) / target) * 100.0
         submit(id: SkyConstants.GameCenter.Achievement.fail50, percent: percent)
     }
  
    // MARK: - 底层上报封装
    
    /// 上报单条成就
    private func submit(id: String, percent: Double) {
        // 确保不超过 100.0
        let safePercent = min(percent, 100.0)
        
        // 调用 GameCenterManager 进行实际的网络请求
        // showBanner: 只有达到 100% 时才弹窗，避免进度更新频繁弹窗打扰
        let showBanner = safePercent >= 100.0
        
        GameCenterManager.shared.unlockAchievement(id: id, percentComplete: percent, showBanner: showBanner)
    }
}
