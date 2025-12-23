//
//  GameCenterManager.swift
//  billiards Watch App
//
//  Created by mac on 2025/11/9.
//

import GameKit
import UIKit


struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: String
    let avatar: UIImage?
}

/// 一个用于处理所有 Game Center 逻辑的管理器 (纯 watchOS, 正确 API 版本)
class GameCenterManager: ObservableObject {
    
    static let shared = GameCenterManager()
    @Published var isAuthenticated = false
    private let localPlayer = GKLocalPlayer.local
    
    private init() {
        setupAuthenticationHandler()
    }
    
    // MARK: - 1. 玩家认证 (终极跨平台修复)
      
      func setupAuthenticationHandler() {
          
          #if os(watchOS)
          // --- 这是在 watchOS 上编译时，会使用的代码 ---
          
          localPlayer.authenticateHandler = { [weak self] error in
              guard let self = self else { return }
              
              if let error = error {
                  print("Game Center (watchOS): Auth Error -> \(error.localizedDescription)")
                
                  #if os(watchOS)

                  UserDefaults.standard.set("Game Center (watchOS): Auth Error -> \(error.localizedDescription)", forKey: "GameCenterFailedToFecht1")
                  UserDefaults.standard.synchronize()

                  #endif

                
                  DispatchQueue.main.async { self.isAuthenticated = false }
                  return
              }
              
              self.updateAuthState()
          }
          
          #elseif os(iOS)
          // --- 这是在 iOS 上编译时，会使用的代码 ---
          
          localPlayer.authenticateHandler = { [weak self] viewController, error in
              guard let self = self else { return }

              if let error = error {
                  print("Game Center (iOS): Auth Error -> \(error.localizedDescription)")
                  DispatchQueue.main.async { self.isAuthenticated = false }
                  return
              }
              
              // 如果需要弹出登录界面 (在 iOS 上很常见)
              if let vc = viewController {
                  // 我们需要一种方法来把这个 vc 呈现给用户
                  // 这里我们先打印一下，表示需要处理
                  print("Game Center (iOS): Needs to present login view controller.")
                  DispatchQueue.main.async {
                    UIApplication.shared.topMostViewController?.present(vc, animated: true)
                  }
                
                  return
              }
              
              self.updateAuthState()
          }
          #endif
          
      }
  
    private func updateAuthState() {
          if self.localPlayer.isAuthenticated {
              print("Game Center: Player successfully authenticated.")
              DispatchQueue.main.async { self.isAuthenticated = true }
          } else {
              print("Game Center: Player not authenticated.")
              DispatchQueue.main.async { self.isAuthenticated = false }
          }
      }
    
    
    // MARK: - 2. 提交分数
    
    func submitScore(_ score: Int, to leaderboardID: String) {
     
        // 在手机上，直接提交
        guard GKLocalPlayer.local.isAuthenticated else { return }
        Task {
            do {
                try await GKLeaderboard.submitScore(score, context: 0, player: localPlayer, leaderboardIDs: [leaderboardID])
                print("Game Center: Score \(score) submitted to \(leaderboardID) successfully.")
            } catch let error {
                print("Game Center: Error submitting score -> \(error.localizedDescription)")
            }
        }
       
    }
  
    // MARK: - 3. 解锁成就
    
    func unlockAchievement(id achievementID: String, percentComplete: Double = 100.0, showBanner: Bool = true) {
       
        // 在手机上，直接解锁
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = showBanner
        
        Task {
            do {
                try await GKAchievement.report([achievement])
                print("Game Center: Achievement \(achievementID) reported successfully.")
            } catch let error {
                print("Game Center: Error reporting achievement -> \(error.localizedDescription)")
            }
        }
      
    }
  
  @available(iOS 14.0, watchOS 7.0, *)
      func fetchLeaderboardEntries(
          for leaderboardID: String,
          timeScope: GKLeaderboard.TimeScope = .allTime,
          range: NSRange = NSRange(location: 1, length: 100)
      ) async -> [LeaderboardEntry] {
          
          //直接返回测试数据
         // return loadMockEntry(timeScope: timeScope).sorted { $0.rank < $1.rank }
        
          guard GKLocalPlayer.local.isAuthenticated else { return [] }
          
          do {
              // 1. 加载排行榜
              let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
              guard let leaderboard = leaderboards.first else { return [] }
              
              // 2. 加载排行榜条目
              let (_, entries, _) = try await leaderboard.loadEntries(for: .global, timeScope: timeScope, range: range)
              
              // ✅ 3. 【性能优化】使用 TaskGroup 并发加载数据
              return try await withThrowingTaskGroup(of: LeaderboardEntry.self) { group in
                  var leaderboardEntries: [LeaderboardEntry] = []
                  leaderboardEntries.reserveCapacity(entries.count)

                  for entry in entries {
                      group.addTask {
                          #if os(iOS)
                          var avatarImage: UIImage? = nil
                          // ✅ 2. 修正了 iOS 加载头像的最低版本要求
                          if #available(iOS 15.0, *) {
                              do {
                                  avatarImage = try await entry.player.loadPhoto(for: .small)
                              } catch {
                                  // 即使单个头像加载失败，也不影响整个流程
                                  print("Failed to load avatar for \(entry.player.displayName): \(error)")
                              }
                          }
                          return LeaderboardEntry(
                              rank: entry.rank,
                              playerName: entry.player.displayName,
                              score: entry.formattedScore,
                              avatar: avatarImage
                          )
                          #elseif os(watchOS)
                          // watchOS 版本不加载头像
                          return LeaderboardEntry(
                              rank: entry.rank,
                              playerName: entry.player.displayName,
                              score: entry.formattedScore,
                              avatar: nil
                          )
                          #endif
                      }
                  }
                  
                  // 从 group 中收集所有完成的任务结果
                  for try await entry in group {
                      leaderboardEntries.append(entry)
                  }
                  
                  // ⚠️ 重要：并发执行会打乱顺序，需要根据排名重新排序
                  return leaderboardEntries.sorted { $0.rank < $1.rank }
              }
              
          } catch {
              print("Game Center: Failed to fetch leaderboard entries -> \(error.localizedDescription)")
             
                #if os(watchOS)
                UserDefaults.standard.set("Game Center: Failed to fetch leaderboard entries -> \(error.localizedDescription)", forKey: "GameCenterFailedToFecht3")
                #endif
               
              return []
          }
      }
  
    func loadMockEntry( timeScope: GKLeaderboard.TimeScope) -> [LeaderboardEntry] {
      // 按 timeScope 返回不同模拟数据
      let simulatedEntries: [LeaderboardEntry]
      switch timeScope {
      case .today:
          simulatedEntries = [
           LeaderboardEntry(rank: 1, playerName: "Alice", score: "3",avatar: nil),
             LeaderboardEntry(rank: 2, playerName: "Bob", score: "2",avatar: nil),
             LeaderboardEntry(rank: 3, playerName: "Charlie", score: "1",avatar: nil)
          ]
      case .week:
          simulatedEntries = [
             LeaderboardEntry(rank: 1, playerName: "Alice", score: "145",avatar: nil),
             LeaderboardEntry(rank: 2, playerName: "Bob", score: "10",avatar: nil),
             LeaderboardEntry(rank: 3, playerName: "Charlie", score: "9",avatar: nil)
          ]
      case .allTime:
         simulatedEntries = (1...100).map { rank in
            LeaderboardEntry(
                rank: rank,
                playerName: "Player \(rank)",
                score: "\(101-rank)",
                avatar: nil
            )
        }

      @unknown default:
          simulatedEntries = []
      }
      
      return simulatedEntries
      
    }
  
}

// --- 扩展支持 asyncMap ---
extension Array {
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        result.reserveCapacity(count)
        for element in self {
            try await result.append(transform(element))
        }
        return result
    }
}



