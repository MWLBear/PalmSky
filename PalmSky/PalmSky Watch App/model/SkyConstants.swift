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
