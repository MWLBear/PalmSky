//
//  SharedDataManager.swift
//  SkyExtension
//
//  Created by mac on 12/18/25.
//

import Foundation
import WidgetKit

//前提： 你需要在 Xcode -> Signing & Capabilities 中，为 Watch App 和 Widget Extension 都添加同一个 App Group（例如 group.com.palmsky）。

// 专门用于 Widget 显示的数据快照
struct ComplicationSnapshot: Codable, Equatable {
    let realmName: String
    let progress: Double // 0.0 - 1.0
    let level: Int
    
    // 默认空数据
    static let empty = ComplicationSnapshot(realmName: "筑基", progress: 0, level: 0)
}

struct SharedDataManager {
    // ⚠️ 替换为你自己的 App Group ID

    // 获取共享 UserDefaults
    static var sharedDefaults: UserDefaults? {
      UserDefaults(suiteName: SkyConstants.UserDefaults.appGroupID)
    }
    
    // 1. 保存快照 (App 调用)
    static func saveSnapshot(player: Player, progress: Double) {
        let snap = ComplicationSnapshot(
            realmName: GameLevelManager.shared.stageName(for: player.level, reincarnation: player.reincarnationCount),
            progress: progress,
            level: player.level
        )
        
        if let data = try? JSONEncoder().encode(snap) {
          sharedDefaults?.set(data, forKey: SkyConstants.UserDefaults.snapshotKey)
            // 保存完立刻刷新 Widget
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
