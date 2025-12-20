//
//  RecordManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/15/25.
//

import Foundation

class RecordManager: ObservableObject {
    static let shared = RecordManager()
    
  // ✨ 新增：前世档案 (虽然暂时不显示，但先存着，以后可以做“三生石”功能)
    @Published var pastLives: [CultivationRecord] = []
  
    @Published var record: CultivationRecord
 

    private init() {
        // 加载记录
      if let data = UserDefaults.standard.data(forKey: SkyConstants.UserDefaults.recordKey),
           let decoded = try? JSONDecoder().decode(CultivationRecord.self, from: data) {
            self.record = decoded
        } else {
            // 新建档案 (第一世)
            self.record = CultivationRecord()
        }
      
      // 2. ✨ 加载前世记录
      if let historyData = UserDefaults.standard.data(forKey: SkyConstants.UserDefaults.recordHistoryKey),
         let history = try? JSONDecoder().decode([CultivationRecord].self, from: historyData) {
         self.pastLives = history
      }
      
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(record) {
          UserDefaults.standard.set(data, forKey: SkyConstants.UserDefaults.recordKey)
        }
    }
  
    // ✨ 保存历史记录 (私有方法)
    private func saveHistory() {
      if let data = try? JSONEncoder().encode(pastLives) {
        UserDefaults.standard.set(data, forKey: SkyConstants.UserDefaults.recordHistoryKey)
      }
    }
    
    // MARK: - 埋点方法
    
    /// 1. 记录登录 (用于更新最后活跃时间)
   func trackLogin(currentRealmName: String) {
        record.lastLoginDate = Date()
        // 顺便检查一下当前的停滞时间，虽然还没突破，但可能已经卡很久了
        updateStagnation(currentRealmName: currentRealmName)

        save()
    }
    
    /// 2. 记录突破尝试
    /// - Parameters:
    ///   - success: 是否成功
    ///   - successRate: 当前的成功率 (用于判断性格)
    ///   - currentRealmName: 境界名字
    func trackBreak(success: Bool, successRate: Double, currentRealmName: String) {
        record.breakAttempts += 1
        
        // 记录性格
        if successRate < 0.6 {
            record.riskyBreakCount += 1
        } else if successRate > 0.9 {
            record.steadyBreakCount += 1
        }
        
        if success {
            // 突破成功，结算上一级的停滞时间
             updateStagnation(currentRealmName: currentRealmName)
            // 重置起跑线
            record.lastBreakDate = Date()
            record.breakSuccesses += 1 // 别忘了加这个

        } else {
            record.breakFailures += 1
        }
        save()
    }
    
    /// 3. 记录奇遇选择
    func trackEvent(accepted: Bool) {
        record.eventsTriggered += 1
        if accepted {
            record.eventsAccepted += 1
        } else {
            record.eventsRejected += 1
        }
        save()
    }
    
    /// 4. 记录飞升 (满级)
    func trackAscension() {
        if record.finishDate == nil {
            record.finishDate = Date()
            save()
        }
    }
    
    // 内部辅助：更新最长卡关时间
    private func updateStagnation(currentRealmName: String) {
        let now = Date()
        let duration = now.timeIntervalSince(record.lastBreakDate)
        if duration > record.longestStagnation {
            record.longestStagnation = duration
            record.longestStagnationStageName = currentRealmName
        }
    }
    
    // MARK: - 重修 (开启下一世)
     func reincarnate() {
         // 1. 确保 finishDate 已记录
         if record.finishDate == nil {
             record.finishDate = Date()
         }
         
         // 2. 存入历史
         pastLives.append(record)
         
         saveHistory() // 👈 这一步非常关键！写入磁盘！
       
         // 3. 重置当前记录 (开启新的一生)
         // 保留一些“灵魂印记”吗？目前先完全重置，保持纯粹
         self.record = CultivationRecord()
         
         // 4. 保存所有数据
         save()
       
         print("轮回成功。已封存第 \(pastLives.count) 世。")
     }
  
  
    // MARK: - 删档重置
    
    /// 清空当前这一世的记录 (用于“散尽修为”功能)
    /// 注意：通常不建议清空 pastLives (历史荣誉)，只清空当前 record
    func resetCurrentRecord() {
      self.record = CultivationRecord() // 新建一张白纸
      save()
    }
    
    // 如果你希望“删档”连历史记录（几世轮回）都删掉，可以用这个：
    func hardResetAll() {
      self.record = CultivationRecord()
      self.pastLives = [] // 清空祖宗十八代
      save()
      saveHistory()
    }
  
  
}
