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
    // 🔥 核心修改：动态上限
    var MAX_DAILY_STEPS: Int {
        return PurchaseManager.shared.hasAccess ? SkyConstants.PRO_STEPS_LIMIT : SkyConstants.FREE_STEPS_LIMIT
    }
  
    // 步数转化倍率 (1步 = 1倍点击收益，鼓励走路)
    private let WALKING_BONUS_RATIO = 1.0
    
    // MARK: - 状态数据
    @Published var todaySteps: Int = 0
    @Published var lastNightSleepHours: Double = 0
    
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
    
    // MARK: - 睡眠闭关数据
    
    /// 睡眠时长对应的离线收益倍率
    var sleepBonusMultiplier: Double {
        switch lastNightSleepHours {
        case 7.5...:
            return 1.25
        case 6.5..<7.5:
            return 1.15
        case 5.5..<6.5:
            return 1.08
        default:
            return 1.0
        }
    }
    
    /// 睡眠档位文案
    var sleepTierTitle: String {
        guard lastNightSleepHours > 0 else {
            return NSLocalizedString("watch_sleep_unavailable", comment: "")
        }
        switch lastNightSleepHours {
        case 7.5...:
            return NSLocalizedString("watch_sleep_tier_best", comment: "")
        case 6.5..<7.5:
            return NSLocalizedString("watch_sleep_tier_good", comment: "")
        case 5.5..<6.5:
            return NSLocalizedString("watch_sleep_tier_ok", comment: "")
        default:
            return NSLocalizedString("watch_sleep_tier_low", comment: "")
        }
    }
    
    /// 展示用的昨夜睡眠时长
    var lastNightSleepDisplay: String {
        guard lastNightSleepHours > 0 else {
            return NSLocalizedString("watch_sleep_unavailable", comment: "")
        }
        let totalMinutes = Int((lastNightSleepHours * 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(
            format: NSLocalizedString("watch_sleep_duration_format", comment: ""),
            hours,
            minutes
        )
    }
    
    /// 展示用的睡眠离线加成
    var sleepBonusDisplay: String {
        guard lastNightSleepHours > 0 else {
            return NSLocalizedString("watch_sleep_unavailable", comment: "")
        }
        let percent = Int(round((sleepBonusMultiplier - 1.0) * 100))
        return "+\(percent)%"
    }
    
    // MARK: - 1. 权限请求
    func requestPermission(completion: (() -> Void)? = nil) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // 只需要读取权限，不需要写入
        healthStore.requestAuthorization(toShare: [], read: [stepType, sleepType]) { success, error in
            DispatchQueue.main.async {
                guard success else {
                    completion?()
                    print("requestAuthorization error")
                    return
                }
                self.fetchTodaySteps()
                self.fetchLastNightSleep {
                    completion?()
                }
            }
        }
    }
    
    // MARK: - 2. 获取今日步数
    func fetchTodaySteps() {
      
              // 🔥 调试专用：如果是模拟器，直接给个假数据
//       #if targetEnvironment(simulator)
////       #if DEBUG
//        DispatchQueue.main.async {
//          // 每次启动给 8888 步，或者随机一个数
//          self.todaySteps = 35000
//          // self.todaySteps = Int.random(in: 1000...20000)
//        }
//        return // 直接返回，不走下面的 HealthKit 查询
//        #endif
      
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
    
    // MARK: - 读取昨夜睡眠
    func fetchLastNightSleep(completion: (() -> Void)? = nil) {
      
//        #if targetEnvironment(simulator)
//        DispatchQueue.main.async {
//            // 模拟器调试：切不同测试值，方便验证睡眠档位与离线加成
////             self.lastNightSleepHours = 5.0  // 养神不足：+0%
//             self.lastNightSleepHours = 6.0  // 气息初稳：+8%
//            // self.lastNightSleepHours = 7.0  // 闭关有成：+15%
//            //self.lastNightSleepHours = 7.8     // 神完气足：+25%
//            completion?()
//        }
//        return
//        #endif
      
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard
            let start = calendar.date(byAdding: .hour, value: -6, to: startOfToday),
            let noon = calendar.date(byAdding: .hour, value: 12, to: startOfToday)
        else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }
        
        let end = min(now, noon)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let clippedIntervals = (samples as? [HKCategorySample] ?? [])
                .filter { self.isAsleepCategoryValue($0.value) }
                .map { sample in
                    (
                        start: max(sample.startDate, start),
                        end: min(sample.endDate, end)
                    )
                }
                .filter { $0.end > $0.start }
                .sorted { $0.start < $1.start }
            
            var mergedIntervals: [(start: Date, end: Date)] = []
            for interval in clippedIntervals {
                guard let last = mergedIntervals.last else {
                    mergedIntervals.append(interval)
                    continue
                }
                
                if interval.start <= last.end {
                    mergedIntervals[mergedIntervals.count - 1].end = max(last.end, interval.end)
                } else {
                    mergedIntervals.append(interval)
                }
            }
            
            let totalSeconds = mergedIntervals.reduce(0.0) { partial, interval in
                partial + interval.end.timeIntervalSince(interval.start)
            }
            
            DispatchQueue.main.async {
                self.lastNightSleepHours = totalSeconds / 3600
                completion?()
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
    
    /// 兼容旧版与新版睡眠分类，统一判断是否属于“入睡”状态
    private func isAsleepCategoryValue(_ value: Int) -> Bool {
        if #available(iOS 16.0, watchOS 9.0, *) {
            return value == HKCategoryValueSleepAnalysis.asleep.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        } else {
            return value == HKCategoryValueSleepAnalysis.asleep.rawValue
        }
    }
}
