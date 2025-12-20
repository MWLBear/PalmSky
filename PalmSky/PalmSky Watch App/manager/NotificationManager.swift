//
//  NotificationManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/19/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // 1. 请求权限 (必须在 App 启动时调用一次)
      func requestPermission() {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
              if granted {
                  print("✅ 通知权限已获取")
              } else {
                  print("❌ 通知权限被拒绝")
              }
          }
      }
    
      // 2. 安排"灵气溢出"通知 (带智能防打扰)
      func scheduleFullGainNotification() {
        cancelNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "道友，灵气已溢出！"
        content.body = "闭关已达上限，速速归来突破瓶颈！"
        content.sound = .default
        
        // --- 🌙 智能时间计算 ---
        let now = Date()
        let targetDuration: TimeInterval = 12  * 60 * 60 // 12小时
        // let targetDuration: TimeInterval = 10 // 测试用：10秒
        
        // 1. 计算原本应该响铃的时间
        let tentativeDate = now.addingTimeInterval(targetDuration)
        
        // 2. 计算最终响铃时间 (避开 22:00 - 08:00)
        let finalTriggerDate = getSmartTriggerDate(originalDate: tentativeDate)
        
        // 3. 计算新的时间间隔
        let finalInterval = finalTriggerDate.timeIntervalSince(now)
        
        // 4. 设置触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: finalInterval, repeats: false)
        
        let request = UNNotificationRequest(identifier: "offline_full", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
          if let error = error {
            print("❌ 通知设置失败: \(error)")
          } else {
            // 打印一下日志，方便调试看时间对不对
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            print("⏳ 通知已设置，将于 [\(formatter.string(from: finalTriggerDate))] 触发")
          }
        }
      }
      
      // 🧠 核心算法：如果落在深夜，推迟到早上 8 点
      private func getSmartTriggerDate(originalDate: Date) -> Date {
          let calendar = Calendar.current
          let hour = calendar.component(.hour, from: originalDate)
          
          // 勿扰时段：晚上 22点 ~ 早上 8点
          // 如果原本的时间落在这个区间里
          if hour >= 22 || hour < 8 {
              // 构造当天的 08:00
              var components = calendar.dateComponents([.year, .month, .day], from: originalDate)
              components.hour = 8
              components.minute = 0
              components.second = 0
              
              guard let morningDate = calendar.date(from: components) else { return originalDate }
              
              // 修正逻辑：
              // 情况 A: 原本是 23:00 (晚上)，我们设成了当天的 08:00 (过去)。需要 +1 天。
              // 情况 B: 原本是 02:00 (凌晨)，我们设成了当天的 08:00 (未来)。不用动。
              
              if morningDate < originalDate {
                  return calendar.date(byAdding: .day, value: 1, to: morningDate)!
              } else {
                  return morningDate
              }
          }
          
          // 如果是白天，直接用原时间
          return originalDate
      }
  
    
    // 3. 取消通知 (回前台时调用)
      func cancelNotifications() {
          let center = UNUserNotificationCenter.current()
          
          // 1. 取消还没响的 (未来的闹钟)
          center.removeAllPendingNotificationRequests()
          
          // 2. ✨ 新增：清除已经响过的 (通知中心里的旧消息)
          // 玩家既然已经打开 App 了，旧的提醒就没意义了，自动帮他清掉，体验更好。
          center.removeAllDeliveredNotifications()
          
          print("🔕 已清理所有相关的通知")
      }
  
}
