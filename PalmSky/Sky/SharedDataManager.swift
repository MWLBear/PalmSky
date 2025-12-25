//
//  SharedDataManager.swift
//  SkyExtension
//
//  Created by mac on 12/18/25.
//

import Foundation
import WidgetKit

//前提： 你需要在 Xcode -> Signing & Capabilities 中，为 Watch App 和 Widget Extension 都添加同一个 App Group（例如 group.com.palmsky）。

struct ComplicationSnapshot: Codable, Equatable {
    let realmName: String
    let level: Int
    
    // 基础数据
    let currentQi: Double       // 存盘时的灵气
    let targetQi: Double        // 升级需要的灵气 (breakCost)
    let rawGainPerSecond: Double // 基础每秒产出 (不含0.8折扣)
    let saveTime: Date          // 存盘时间
    
    // 🔥 核心：复刻 App 的离线计算逻辑
    func getPredictedProgress(at date: Date) -> Double {
        // 1. 计算时间差
        let timeDiff = date.timeIntervalSince(saveTime)
        
        // 如果时间是负的（系统误差），直接返回当前进度
        if timeDiff <= 0 { return currentQi / max(targetQi, 1.0) }
        
        // 2. 复刻逻辑：12小时上限 (12 * 60 * 60 = 43200)
        let maxOfflineSeconds: TimeInterval = 43200
        let effectiveTime = min(timeDiff, maxOfflineSeconds)
        
        // 3. 复刻逻辑：0.8 倍率
        // 注意：这里忽略了 5分钟阈值。
        // 原因：表盘刷新频率通常大于5分钟，且视觉上玩家希望看到进度条在动。
        // 如果非要加，可以写 if timeDiff < 300 { return currentQi / targetQi }
        let offlineGain = rawGainPerSecond * effectiveTime * 0.8
        
        // 4. 计算总灵气
        let predictedTotalQi = currentQi + offlineGain
        
        // 5. 计算进度 (封顶 1.0)
        if targetQi <= 0 { return 1.0 }
        return min(predictedTotalQi / targetQi, 1.0)
    }
    
    // 默认空数据
    static let empty = ComplicationSnapshot(
        realmName: "筑基", level: 1,
        currentQi: 30, targetQi: 100, rawGainPerSecond: 1, saveTime: Date()
    )

}


struct SharedDataManager {
    // ⚠️ 替换为你自己的 App Group ID

    // 获取共享 UserDefaults
    static var sharedDefaults: UserDefaults? {
      UserDefaults(suiteName: SkyConstants.UserDefaults.appGroupID)
    }
    
    // 1. 保存快照 (App 调用)
    static func saveSnapshot(player: Player, breakCost: Double, rawAutoGain: Double) {
      let snap = ComplicationSnapshot(
        realmName: GameLevelManager.shared.stageName(for: player.level, reincarnation: player.reincarnationCount),
        level: player.level,
        currentQi: player.currentQi,
        targetQi: breakCost,
        rawGainPerSecond: rawAutoGain, // 传入基础速度
        saveTime: Date()
      )
      
      if let data = try? JSONEncoder().encode(snap) {
        sharedDefaults?.set(data, forKey: SkyConstants.UserDefaults.snapshotKey)
        reloadComplications()
      }
    }
    
    // 2. 读取快照 (Widget 调用)
    static func loadSnapshot() -> ComplicationSnapshot {
      guard let data = sharedDefaults?.data(forKey: SkyConstants.UserDefaults.snapshotKey),
              let snap = try? JSONDecoder().decode(ComplicationSnapshot.self, from: data)
        else {
            return .empty
        }
        return snap
    }
    
    // 3. 刷新 Widget
    static func reloadComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "XiuxianComplication")
    }
}
