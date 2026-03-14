import Foundation

// MARK: - Event Pool
class EventPool {
    static let shared = EventPool()
    private(set) var events: [GameEvent] = []
    // 护身符库存过高时，不再继续从奇遇中免费投放，避免冲淡付费价值
    private let charmEventBlockThreshold = 50

    private init() {
         loadEvents()
     }

     private func loadEvents() {
         guard
             let url = Bundle.main.url(forResource: "events", withExtension: "json"),
             let data = try? Data(contentsOf: url)
         else {
             print("❌ events.json 加载失败")
             return
         }

         do {
             events = try JSONDecoder().decode([GameEvent].self, from: data)
             print("✅ 已加载事件数量: \(events.count)")
         } catch {
             print("❌ JSON 解析失败:", error)
         }
     }
    
   
    // MARK: - ✨ 核心：根据玩家等级随机事件
    func randomEvent(playerLevel: Int, protectCharmCount: Int = 0) -> GameEvent? {
      // 1. 获取玩家当前的大境界索引 (0..15)
      let playerStageIndex = (playerLevel - 1) / 9
      
      // 2. 筛选符合条件的事件
      let validEvents = events.filter { event in
        // A. 检查最低境界限制
        if let minStr = event.minStage,
           let minIndex = GameConstants.stageIndex(for: minStr),
           playerStageIndex < minIndex {
          return false // 玩家境界太低，遇不到
        }
        
        // B. 检查最高境界限制
        if let maxStr = event.maxStage,
           let maxIndex = GameConstants.stageIndex(for: maxStr),
           playerStageIndex > maxIndex {
          return false // 玩家境界太高，不再遇到低级事
        }
        
        return true
      }
      
      // 3. 护身符库存过高时，运行时拦截“送护身符”事件，避免越送越多
      let eligibleEvents: [GameEvent]
      if protectCharmCount >= charmEventBlockThreshold {
        let filteredEvents = validEvents.filter { !containsGrantItemEvent($0) }
        eligibleEvents = filteredEvents.isEmpty ? validEvents : filteredEvents
      } else {
        eligibleEvents = validEvents
      }
      
      // 4. 从符合条件的池子里随机
      // (进阶：这里可以根据 rarity 稀有度加权随机，目前先做均等随机)
      if eligibleEvents.isEmpty {
        print("⚠️ 当前境界没有匹配的事件，返回通用事件或 nil")
        // 建议在 JSON 里放一些没有 min/max 限制的通用事件兜底
        return events.filter { $0.minStage == nil && $0.maxStage == nil }.randomElement()
      }
      
      return eligibleEvents.randomElement()
    }
 
    /// 判断事件是否包含“赠送护身符”这一类道具奖励
    private func containsGrantItemEvent(_ event: GameEvent) -> Bool {
      event.choices.contains { $0.effect.type == .grantItem }
    }
    
    func eventById(_ id: String) -> GameEvent? {
        return events.first { $0.id == id }
    }
}
