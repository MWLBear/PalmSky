//
//  File.swift
//  PalmSky Watch App
//
//  Created by mac on 12/19/25.
//

import Foundation

struct SkyConstants {
  
  /// 用于管理 UserDefaults 的键
  struct UserDefaults {
    
    static let userDefaultsKey = "savedPlayer"
    
    static let recordKey = "cultivation_life_record_v1"
    static let recordHistoryKey = "cultivation_history_v1" // 新的 Key
    
    static let appGroupID = "group.com.palmsky"
    static let snapshotKey = "complication_snapshot_v1"
    
  }
  
  struct GameCenter {
    
    enum Leaderboard: String {
      case playerLevel = "sky_player_level"
      case playerClick = "sky_player_clicks"
    }
    
    // MARK: - Game Center 成就 IDs
      struct Achievement {
        // --- 境界成就 ---
        static let realmFoundation = "ach_realm_foundation" // 筑基 (Lv 1)
        static let realmPigu       = "ach_realm_pigu"       // ✨ 辟谷 (Lv 28)
        static let realmCore       = "ach_realm_core"       // 金丹 (Lv 37)
        static let realmNascent    = "ach_realm_nascent"    // 元婴 (Lv 46)
        static let realmDemigod    = "ach_realm_demigod"    // ✨ 分神 (Lv 64)
        static let realmTribulation = "ach_realm_tribulation" // ✨ 渡劫 (Lv 91)
        static let realmEarth      = "ach_realm_earth"      // ✨ 地仙 (Lv 100)
        static let ascension       = "ach_ascension"        // 飞升 (Lv 144)
        
        // --- 苦修成就 ---
        static let tap10k   = "ach_tap_10k"    // 1万
        static let tap50k   = "ach_tap_50k"    // ✨ 5万
        static let tap100k  = "ach_tap_100k"   // ✨ 10万
        static let tap1m    = "ach_tap_1m"     // ✨ 100万 (终极目标)
        
        // --- 其他保持不变 ---
        static let fail10 = "ach_fail_10"
        static let fail50 = "ach_fail_50"
        static let reincarnation1 = "ach_reincarnation_1"
      }
    
  }
  
  struct WatchSync {
    // MARK: - General
    /// 消息的主动作指令 (e.g., "fetchLeaderboard")
    static let action = "action"
    
    // MARK: - Actions (Value of "action" key)
    /// 同步核心游戏数据的动作
    static let syncGameData = "syncGameData"
    
    /// 消息中包含的核心游戏数据
    static let gameData = "gameData"
    
    static let fetchLeaderboard = "fetchLeaderboard"
    
    /// 排行榜 ID
    static let leaderboardID = "leaderboardID"
    /// 排行榜的时间范围 (日/周/总)
    static let timeScope = "timeScope"
    /// 消息中包含的排行榜数据
    static let leaderboardData = "leaderboardData"
    
  }
  
  
}
