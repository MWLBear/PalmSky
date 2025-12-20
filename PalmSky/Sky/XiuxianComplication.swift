import WidgetKit
import SwiftUI

// MARK: - 1. Timeline Entry
struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: ComplicationSnapshot
}

// MARK: - 2. Provider
struct Provider: TimelineProvider {
    
    // ❌ 修正点 3: Placeholder 数据更合理 (30% 刚起步)
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: Date(),
            snapshot: .init(realmName: "筑基", progress: 0.3, level: 1)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {

      let entry = ComplicationEntry(date: Date(), snapshot: .init(realmName: "筑基", progress: 0.3, level: 1))
      completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let currentDate = Date()
        let snap = SharedDataManager.loadSnapshot()
        
        let entry = ComplicationEntry(date: currentDate, snapshot: snap)
        
        // 30分钟后尝试刷新 (兜底策略)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

}

// MARK: - 3. Entry View (UI 核心)
struct XiuxianComplicationEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // ✅ 优化 1: 动态颜色逻辑 (>=90% 变橙色预警)
    var progressColor: Color {
        entry.snapshot.progress >= 0.9 ? .orange : .green
    }
    
    var body: some View {
      
        let stageColor = RealmColor.gradient(for: entry.snapshot.level).last ?? .green

        switch family {
            
        case .accessoryCircular:
          
            Gauge(value: entry.snapshot.progress, in: 0...1) {
              Text(entry.snapshot.realmName)
                .font(.system(size: 10, weight: .bold)) // 基础字号
                .minimumScaleFactor(0.4) // 允许缩小到 40% 以塞进更多字
                .lineLimit(1) // 强制一行
            } currentValueLabel: {
              Text("\(Int(entry.snapshot.progress * 100))%")
                                 .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.circular)
            .tint(stageColor) // 动态变色
            
        case .accessoryCorner:
            // ❌ 修正点 2: .widgetLabel 仅在此处使用
            Text(entry.snapshot.realmName)
                .font(.system(size: 12, weight: .medium))
                .widgetLabel {
                    Gauge(value: entry.snapshot.progress, in: 0...1) {
                        Text("\(Int(entry.snapshot.progress * 100))%")
                    }
                    .tint(stageColor) // 角标进度条也变色
                }
            
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.snapshot.realmName)
                        .font(.headline)
                        .widgetAccentable() // 允许系统着色
                    
                    // 状态文案
                    Text(entry.snapshot.progress >= 0.9 ? "瓶颈松动" : "修炼中...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // 右侧进度
                VStack(alignment: .trailing) {
                    Text("\(Int(entry.snapshot.progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(progressColor)
                    
                    ProgressView(value: entry.snapshot.progress)
                        .progressViewStyle(.linear)
                        .tint(progressColor)
                }
                .frame(width: 44)
            }
            
        case .accessoryInline:
            // ✅ 优化 2: 文案加点 (·) 更优雅
            Text("\(entry.snapshot.realmName) · \(Int(entry.snapshot.progress * 100))%")
            
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
            .widgetURL(deeplinkURL(for: entry.snapshot))
          
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
  
    func deeplinkURL(for snap: ComplicationSnapshot) -> URL {
        if snap.progress >= 0.9 {
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






