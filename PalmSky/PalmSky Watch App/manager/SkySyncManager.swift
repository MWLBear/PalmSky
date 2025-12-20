//
//  SkySyncManager.swift
//  Billiards
//
//  Created by mac on 2025/11/10.
//

import Foundation
import WatchConnectivity
import Combine
import GameKit

// 1. 定义一个简单的数据结构来传递数据，比字典更安全

// 为排行榜数据传输定义的可编码结构体
struct CodableLeaderboardEntry: Codable {
    let rank: Int
    let playerName: String
    let score: String
}


class SkySyncManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = SkySyncManager()

    @Published var activationState: WCSessionActivationState = .notActivated
    @Published var isReachable: Bool = false

     #if os(iOS)
     @Published var isWatchAppInstalled: Bool = false
     #endif

    @Published var syncedData: Player?
    @Published var leaderboardEntries: [LeaderboardEntry] = []


    private let session: WCSession

    // 防止重复同步的锁和计时器
    private var syncLock = false
    private var syncTimer: Timer?
    private var pendingDataChanges = false

    private init(session: WCSession = .default) {
          self.session = session
          super.init()
      
          #if os(iOS)
           // 🔥 iOS 端启动时，立刻加载缓存
           loadLocalCache()
           #endif
      
      }
  
    func activate() {
         if WCSession.isSupported() {
             self.session.delegate = self
             self.session.activate()
         }
     }
  
  
  // 1. 公开的方法：尝试加载本地缓存 (供 init 或 View 调用)
   func loadLocalCache() {
       if let data = UserDefaults.standard.data(forKey:  SkyConstants.UserDefaults.userDefaultsKey),
          let player = try? JSONDecoder().decode(Player.self, from: data) {
           
           DispatchQueue.main.async {
               self.syncedData = player
               print("📱 Phone: 已加载本地缓存数据 (Lv.\(player.level))")
           }
       }
   }
  
    // MARK: - Delegate Methods & Message Handling
    private func routeMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        if let action = message[SkyConstants.WatchSync.action] as? String {
            #if os(watchOS)
            // WatchOS receives data from phone
            switch action {
              
            case SkyConstants.WatchSync.leaderboardData:
                handleLeaderboardDataMessage(message)
            default:
                print("WatchSync (watchOS): Received unknown action '\(action)'.")
            }
            #elseif os(iOS)
            // iOS receives requests from watch
            switch action {
            case SkyConstants.WatchSync.syncGameData:
                handleSyncGameData(message)
            case SkyConstants.WatchSync.fetchLeaderboard:
//                handleFetchLeaderboardRequest(message)
                  handleFetchLeaderboardRequest(message, replyHandler: replyHandler)
            default:
                print("WatchSync (iOS): Received unknown action '\(action)'.")
            }
            #endif
        } else {
            print("WatchSync: Received a message with no action key.")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.activationState = activationState
            #if os(iOS)
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
            print("WatchSync (iOS): Session activated, state=\(activationState.rawValue), installed=\(session.isWatchAppInstalled), reachable=\(session.isReachable)")
            #else
            self.isReachable = session.isReachable
            print("WatchSync (watchOS): Session activated, state=\(activationState.rawValue), reachable=\(session.isReachable)")
            #endif
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(iOS)
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
            print("WatchSync: Reachability changed to \(session.isReachable)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        routeMessage(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        routeMessage(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        routeMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
//        routeMessage(message)
//        replyHandler([:]) // Send an empty reply
          routeMessage(message, replyHandler: replyHandler)

    }
}

// MARK: - watchOS: Sending & Receiving Logic
#if os(watchOS)
extension SkySyncManager {
    
    // 触发向手机发送数据的请求
    func sendDataToPhone(player: Player? = nil) {
        print("WatchSync (watchOS):sendDataToPhone")
        guard activationState == .activated else { return }

        if syncLock {
            pendingDataChanges = true
            print("WatchSync (watchOS): Sync in progress, marking pending changes.")
            return
        }
      
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
          // 如果没传参数，再去读（兜底），传了就用传的
            let dataToSend = player ?? self?.getLatestGameData() ?? Player()
            self?.performSync(player: dataToSend)

        }
    }

    private func performSync(player: Player) {

        guard !syncLock else {
            pendingDataChanges = true
            return
        }

        syncLock = true
        defer { syncLock = false }

        let latestData = player // 直接用参数

        print("WatchSync (watchOS): Preparing to send data: \(latestData)")

        do {
            let gameDataAsData = try JSONEncoder().encode(latestData)
            let message: [String: Any] = [
                SkyConstants.WatchSync.action: SkyConstants.WatchSync.syncGameData,
                SkyConstants.WatchSync.gameData: gameDataAsData
            ]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    print("WatchSync (watchOS): sendMessage failed -> \(error.localizedDescription)")
                }
            }
           // try session.updateApplicationContext(message)
            session.transferUserInfo(message) //保证送达

            if pendingDataChanges {
                pendingDataChanges = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.sendDataToPhone()
                }
            }
        } catch {
            print("WatchSync (watchOS): Error encoding/sending data -> \(error.localizedDescription)")
        }
    }

      private func getLatestGameData() -> Player {
        if let data = UserDefaults.standard.data(forKey: SkyConstants.UserDefaults.userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Player.self, from: data) {
          return decoded
        } else {
          return Player()
        }
      }
      

    func requestLeaderboardData(leaderboardID: String, timeScope: GKLeaderboard.TimeScope) {
      
        print("WatchSync (watchOS): requestLeaderboardData.")

        guard activationState == .activated && session.isReachable else {
            print("WatchSync (watchOS): iPhone is not reachable. Cannot fetch leaderboard.")
            DispatchQueue.main.async { self.leaderboardEntries = [] }
            return
        }

        let message: [String: Any] = [
            SkyConstants.WatchSync.action: SkyConstants.WatchSync.fetchLeaderboard,
            SkyConstants.WatchSync.leaderboardID: leaderboardID,
            SkyConstants.WatchSync.timeScope: timeScope.rawValue
        ]
        
      // 直接用回调获取手机端的数据更安全
        session.sendMessage(message, replyHandler: { response in
           print("WatchSync (watchOS): response form iphone.",response)
           self.handleLeaderboardDataMessage(response)
        }, errorHandler: { error in
            // fallback: show toast, 或者使用 transferUserInfo fallback
            print("WatchSync (watchOS): Failed to send leaderboard request: \(error.localizedDescription)")
        })
      
    }
  
    private func handleLeaderboardDataMessage(_ message: [String: Any]) {
        guard let data = message[SkyConstants.WatchSync.leaderboardData] as? Data else {
            return
        }
        do {
            let decodedEntries = try JSONDecoder().decode([CodableLeaderboardEntry].self, from: data)
            let entries = decodedEntries.map {
                LeaderboardEntry(rank: $0.rank, playerName: $0.playerName, score: $0.score, avatar: nil)
            }
            DispatchQueue.main.async {
                self.leaderboardEntries = entries
            }
        } catch {
            print("WatchSync (watchOS): Error decoding leaderboard data: \(error)")
        }
    }
}
#endif

// MARK: - iOS: Receiving & Sending Logic
#if os(iOS)
extension SkySyncManager {
  
    private func handleSyncGameData(_ message: [String: Any]) {
      print("WatchSync (iPhone): handleSyncGameData.",message)

      guard let gameData = message[SkyConstants.WatchSync.gameData] as? Data else {
        return
      }
      Task { await processIncomingGameData(gameData) }
    }
    
    private func processIncomingGameData(_ gameData: Data) async {
      do {
        let player = try JSONDecoder().decode(Player.self, from: gameData)
        
        await MainActor.run {
          self.syncedData = player
          
          UserDefaults.standard.set(gameData, forKey: SkyConstants.UserDefaults.userDefaultsKey)

          // 仅当玩家至少赢过一局才处理相关成就 & 提交分数
          // --- 提交 Game Center ---
          if player.level > 0 {
            print("WatchSync (iOS): processIncomingGameData submitScore",player.level)
            
            // ✅ 使用封装好的公式计算总分
            let totalScore = GameLevelManager.shared.calculateTotalScore(
              level: player.level,
              reincarnation: player.reincarnationCount
            )
            
            // 提交总胜利数到 Game Center 排行榜
            GameCenterManager.shared.submitScore(Int(totalScore), to: SkyConstants.GameCenter.Leaderboard.playerLevel.rawValue)
          
          }
          
          if player.click > 0 {
            
            GameCenterManager.shared.submitScore(player.click, to: SkyConstants.GameCenter.Leaderboard.playerClick.rawValue)

          }
       
        }
      } catch {
        print("WatchSync (iOS): Error decoding incoming GameData -> \(error.localizedDescription)")
      }
    }
    
    private func handleFetchLeaderboardRequest(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
      guard let leaderboardID = message[SkyConstants.WatchSync.leaderboardID] as? String,
            let timeScopeRaw = message[SkyConstants.WatchSync.timeScope] as? Int,
            let timeScope = GKLeaderboard.TimeScope(rawValue: timeScopeRaw) else {
        return
      }
      
      Task {
        let entries = await GameCenterManager.shared.fetchLeaderboardEntries(for: leaderboardID, timeScope: timeScope)
        let codableEntries = entries.map {
          CodableLeaderboardEntry(rank: $0.rank, playerName: $0.playerName, score: $0.score)
        }
        do {
          let data = try JSONEncoder().encode(codableEntries)
          let responseMessage: [String: Any] = [
            SkyConstants.WatchSync.action: SkyConstants.WatchSync.leaderboardData,
            SkyConstants.WatchSync.leaderboardData: data
          ]
          if let reply = replyHandler {
            print("WatchSync (iPhone): handleFetchLeaderboardRequest ->CallBackDataToWatch.",message)

            reply(responseMessage)
          } else {
            
            if session.isReachable {
              print("WatchSync (iPhone): handleFetchLeaderboardRequest ->sendMessageToWatch.",message)

              session.sendMessage(responseMessage, replyHandler: nil) { error in
                print("WatchSync (iOS): Failed to send leaderboard data back to watch: \(error.localizedDescription)")
              }
            }
          }
        } catch {
          print("WatchSync (iOS): Error encoding or sending leaderboard data: \(error)")
        }
      }
    }
  
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
      session.activate()
    }
}
#endif
