import WidgetKit
import SwiftUI

// MARK: - 1. Timeline Entry
struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: ComplicationSnapshot
    let displayProgress: Double //用于显示的预测进度
}

// MARK: - 2. Provider
struct Provider: TimelineProvider {
    
    // ❌ 修正点 3: Placeholder 数据更合理 (30% 刚起步)
    func placeholder(in context: Context) -> ComplicationEntry {
      
      let fakeSnapshot = ComplicationSnapshot(
                 realmName: "筑基",
                 level: 1,
                 currentQi: 30,
                 targetQi: 100,
                 rawGainPerSecond: 1, // 随便填，占位用
                 saveTime: Date()
             )
      
      return ComplicationEntry(
                 date: Date(),
                 snapshot: fakeSnapshot,
                 displayProgress: 0.3 // 🔥 必须传这个，View 靠它显示进度
             )
    }
  
  func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
          
          let entry: ComplicationEntry
          
          if context.isPreview {
              // 👉 情况 A：用户正在选表盘 (Gallery)
              // 给一个"好看"的假数据，吸引用户添加
              let fakeSnap = ComplicationSnapshot(
                  realmName: "金丹", // 选个中等境界，好看
                  level: 37,
                  currentQi: 8800,
                  targetQi: 10000,
                  rawGainPerSecond: 10,
                  saveTime: Date()
              )
              // 进度设为 88% 比较美观
              entry = ComplicationEntry(date: Date(), snapshot: fakeSnap, displayProgress: 0.88)
              
          } else {
              // 👉 情况 B：用户真把表盘加上了 (Dock/AOD)
              // 必须读写真实存档，否则用户会觉得数据没同步
              let realSnap = SharedDataManager.loadSnapshot()
              let now = Date()
              let progress = realSnap.getPredictedProgress(at: now)
              
              entry = ComplicationEntry(date: now, snapshot: realSnap, displayProgress: progress)
          }

          completion(entry)
      }
  

  func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
          let currentDate = Date()
          let snap = SharedDataManager.loadSnapshot()
          
           print("------------- 开始生成时间线 -------------")
           print("当前时间: \(currentDate)")
           print("存档时间: \(snap.saveTime)")
           print("基础灵气: \(snap.currentQi)")
           print("每秒产出: \(snap.rawGainPerSecond)")
    
          var entries: [ComplicationEntry] = []
          
          // 策略：生成未来 4 小时的时间线，每 10 分钟刷新一次
          // 为什么是 10 分钟？为了节省系统配额，且修仙进度通常比较慢，10分钟跳变一次足够了。
          // 如果想更流畅，可以设为 5 分钟。
          let intervalMinutes = 5
          let hoursToPredict = 4
          let steps = (hoursToPredict * 60) / intervalMinutes
          
          for i in 0...steps {
              let entryDate = Calendar.current.date(byAdding: .minute, value: i * intervalMinutes, to: currentDate)!
              
              // 🔥 调用刚才写的预测逻辑 (包含 0.8 倍率和 12h 上限)
              let predictedProgress = snap.getPredictedProgress(at: entryDate)
              
              let entry = ComplicationEntry(
                  date: entryDate,
                  snapshot: snap,
                  displayProgress: predictedProgress // 传给 View 显示
              )
              entries.append(entry)
              
              // 如果预测进度已满，就不需要生成后面的了
              if predictedProgress >= 1.0 { break }
          }

          // 设定下次刷新时间
          let nextRefresh = Calendar.current.date(byAdding: .hour, value: hoursToPredict, to: currentDate)!
          let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
          
          completion(timeline)
      }

}

// MARK: - 3. Entry View (UI 核心)
struct XiuxianComplicationEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // ✅ 优化 1: 动态颜色逻辑 (使用 displayProgress)
    var progressColor: Color {
        entry.displayProgress >= 0.9 ? .orange : .green
    }
    
    var body: some View {
        
        let stageColor = RealmColor.gradient(for: entry.snapshot.level).last ?? .green

        switch family {
            
          case .accessoryCircular:
          
            // 判断是否满进度
            if entry.displayProgress >= 0.99 { // 稍微宽容一点，0.99就算满
              // MARK: - 🎉 满级特效状态
              Gauge(value: 1.0, in: 0...1) {
                // 1. 顶部状态：圆满
                Text("渡劫")
                  .font(.system(size: 10, weight: .bold, design: .rounded))
              } currentValueLabel: {

                Image(systemName: "bolt.fill")
                .font(.system(size: 22))
                .symbolRenderingMode(.hierarchical)
                
              }
              .gaugeStyle(.circular)
              // 颜色：使用金红渐变，代表雷劫之火
//              .tint(Gradient(colors: [.yellow, .orange, .red]))
              .tint(
                RealmColor.tribulationGradient(for: entry.snapshot.level)
              )
              
                                     
            } else {
              
              // MARK: - 普通状态 (仿官方天气/电量风格)
                Gauge(value: entry.displayProgress, in: 0...1) {
                  // 1. 顶部/底部的境界名 (根据表盘不同，位置会自动调整)
                  Text(entry.snapshot.realmName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                } currentValueLabel: {
                  // ✨ 核心修改：大数字 + 小符号
                  // 使用 SwiftUI 的 Text 拼接特性
                  (
                    Text("\(Int(entry.displayProgress * 100))")
                      .font(.system(size: 20, weight: .semibold, design: .rounded)) // 数字极大、极粗
                      .monospacedDigit() // 数字等宽，防止跳动
                    +
                    Text("%")
                      .font(.system(size: 12, weight: .semibold, design: .rounded)) // 符号小巧
                     
                  )
                  // 整体允许微缩，防止"100%"爆框
                  .minimumScaleFactor(0.7)
                }
                .gaugeStyle(.circular)
                .tint(stageColor)
               
            }
          
            
        case .accessoryCorner:
            Text(entry.snapshot.realmName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .widgetLabel {
                    // ❌ 修正：使用 displayProgress
                    Gauge(value: entry.displayProgress, in: 0...1) {
                        Text("\(Int(entry.displayProgress * 100))%")
                    }
                    .tint(stageColor)
                }
            
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.snapshot.realmName)
                        .font(.headline)
                        .widgetAccentable()
                    
                    // ❌ 修正：使用 displayProgress 判断文案
                    Text(entry.displayProgress >= 0.9 ? "瓶颈松动" : "修炼中...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // 右侧进度
                VStack(alignment: .trailing) {
                    // ❌ 修正：使用 displayProgress
                    Text("\(Int(entry.displayProgress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(progressColor)
                    
                    // ❌ 修正：使用 displayProgress
                    ProgressView(value: entry.displayProgress)
                        .progressViewStyle(.linear)
                        .tint(progressColor)
                }
                .frame(width: 44)
            }
            
        case .accessoryInline:
            // ❌ 修正：使用 displayProgress
            Text("\(entry.snapshot.realmName) · \(Int(entry.displayProgress * 100))%")
            
        default:
            Text(entry.snapshot.realmName)
        }
    }
}

// MARK: - 4. Main Configuration

struct XiuxianComplication: Widget {
    let kind: String = "XiuxianComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            XiuxianComplicationEntryView(entry: entry)
                // ✅ 修正：传入 entry.displayProgress 来判断跳转
                .widgetURL(deeplinkURL(progress: entry.displayProgress))
        }
        .configurationDisplayName("修炼进度")
        .description("展示当前的境界与灵气进度")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
  
    // ✅ 修改 helper 方法，接收 Double 类型的进度
    func deeplinkURL(progress: Double) -> URL {
        // 如果预测进度显示满了，点击直接跳去突破界面
        if progress >= 0.9 {
            return URL(string: "palmSky://breakthrough")!
        } else {
            return URL(string: "palmSky://main")!
        }
    }
}

@main
struct XiuxianWidgets: WidgetBundle {
    var body: some Widget {
      XiuxianComplication()
      XiuxianEntranceWidget()
    }
}






