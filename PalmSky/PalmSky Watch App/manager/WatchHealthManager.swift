//
//  WatchHealthManager.swift
//  PalmSky Watch App
//
//  Created by mac on 12/28/25.
//

import Foundation
import HealthKit
import SwiftUI

class WatchHealthManager: ObservableObject {
    static let shared = WatchHealthManager()
    private let healthStore = HKHealthStore()
    
    // MARK: - 配置常量
    // 每日有效步数上限 (防止摇步器刷数值崩坏)
    let MAX_DAILY_STEPS = 30_000
    
    // 步数转化倍率 (1步 = 1倍点击收益，鼓励走路)
    private let WALKING_BONUS_RATIO = 1.0
    
    // MARK: - 状态数据
    @Published var todaySteps: Int = 0
    
    // MARK: - 持久化数据
    // 记录哪天的数据 (格式: yyyy-MM-dd)
    @AppStorage("health_last_record_date") private var lastRecordDate: String = ""
    // 今日已经炼化了多少步
    @AppStorage("health_refined_steps") var refinedStepsToday: Int = 0
    
    // MARK: - 计算属性
    
    /// 当前可供炼化的步数
    var stepsAvailableToRefine: Int {
      
        // 1. 检查是否跨天 (如果日期不对，说明今日还没炼化过，或者数据过时)
        if !isSameDay() {
            // 新的一天，还未重置前，可炼化的是当前步数 (卡上限)
            return min(todaySteps, MAX_DAILY_STEPS)
        }
        
        // 2. 计算剩余 (卡上限)
        let effectiveSteps = min(todaySteps, MAX_DAILY_STEPS)
        let result =  max(0, effectiveSteps - refinedStepsToday)
      
//        // 🔥🔥🔥 加上这几行打印进行调试 🔥🔥🔥
//        print("--------------------")
//        print("🤖 步数调试:")
//        print("   今日步数 (today): \(todaySteps)")
//        print("   每日上限 (max): \(MAX_DAILY_STEPS)")
//        print("   有效步数 (effective): \(effectiveSteps)")
//        print("   已炼化 (refined): \(refinedStepsToday)")
//        print("   👉 结果 (result): \(result)")
//        print("--------------------")
//      
        return result
    }
    
    private init() {
        // 初始化时检查一次日期
        checkDateReset()
    }
    
    // MARK: - 1. 权限请求
    func requestPermission() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // 只需要读取权限，不需要写入
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.fetchTodaySteps()
                }
            }
        }
    }
    
    // MARK: - 2. 获取今日步数
    func fetchTodaySteps() {
      
              // 🔥 调试专用：如果是模拟器，直接给个假数据
//        #if targetEnvironment(simulator)
       #if DEBUG
        DispatchQueue.main.async {
          // 每次启动给 8888 步，或者随机一个数
          self.todaySteps = 22000
          // self.todaySteps = Int.random(in: 1000...20000)
        }
        return // 直接返回，不走下面的 HealthKit 查询
        #endif
      
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                // 更新步数
                self.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                // 顺便检查一下跨天逻辑
                self.checkDateReset()
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - 3. 核心：炼化逻辑
    /// 将步数转化为灵气
    /// - Parameter perStepValue: 当前等级单次点击的收益 (baseTapGain)
    /// - Returns: 获得的灵气总量
    func refine(perStepValue: Double) -> Double {
        // 1. 再次检查跨天重置
        checkDateReset()
        
        // 2. 获取可炼化数量
        let available = stepsAvailableToRefine
        
        if available > 0 {
            // 3. 累加到今日已炼化
            refinedStepsToday += available
            
            // 4. 计算灵气收益
            // 公式：步数 * (当前点击收益 * 1.0)
            // 确保后期等级高了之后，走路依然有价值
            let totalGain = Double(available) * perStepValue * WALKING_BONUS_RATIO
            
            return totalGain
        }
        
        return 0
    }
    
    // MARK: - 辅助逻辑
    
    /// 检查是否跨天，如果是新的一天，重置已炼化计数
    private func checkDateReset() {
        let todayStr = getTodayString()
        if lastRecordDate != todayStr {
            // 是新的一天
            lastRecordDate = todayStr
            refinedStepsToday = 0
            // 注意：todaySteps 会由 HealthKit 在 fetch 时自动变回 0
            // 但为了防止 fetch 延迟导致误用旧数据，这里手动置零
            self.todaySteps = 0
        }
    }
    
    private func isSameDay() -> Bool {
        return lastRecordDate == getTodayString()
    }
    
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
