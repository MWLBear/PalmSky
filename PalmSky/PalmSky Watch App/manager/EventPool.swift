import Foundation

// MARK: - Event Pool
class EventPool {
    static let shared = EventPool()
    private(set) var events: [GameEvent] = []

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
    func randomEvent(playerLevel: Int) -> GameEvent? {
      // 1. 获取玩家当前的大境界索引 (0..15)
      let playerStageIndex = (playerLevel - 1) / 9
      
      // 2. 筛选符合条件的事件
      let validEvents = events.filter { event in
        // A. 检查最低境界限制
        if let minStr = event.minStage,
           let minIndex = GameConstants.stageNames.firstIndex(of: minStr),
           playerStageIndex < minIndex {
          return false // 玩家境界太低，遇不到
        }
        
        // B. 检查最高境界限制
        if let maxStr = event.maxStage,
           let maxIndex = GameConstants.stageNames.firstIndex(of: maxStr),
           playerStageIndex > maxIndex {
          return false // 玩家境界太高，不再遇到低级事
        }
        
        return true
      }
      
      // 3. 从符合条件的池子里随机
      // (进阶：这里可以根据 rarity 稀有度加权随机，目前先做均等随机)
      if validEvents.isEmpty {
        print("⚠️ 当前境界没有匹配的事件，返回通用事件或 nil")
        // 建议在 JSON 里放一些没有 min/max 限制的通用事件兜底
        return events.filter { $0.minStage == nil && $0.maxStage == nil }.randomElement()
      }
      
      return validEvents.randomElement()
    }
 
    
    func eventById(_ id: String) -> GameEvent? {
        return events.first { $0.id == id }
    }
}
