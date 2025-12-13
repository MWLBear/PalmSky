import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(ClockKit)
import ClockKit
#endif


//// MARK: - Complication Provider
//struct ComplicationProvider: TimelineProvider {
//    typealias Entry = ComplicationEntry
//    
//    func placeholder(in context: Context) -> ComplicationEntry {
//        ComplicationEntry(
//            date: Date(),
//            realm: "筑基",
//            progressPct: 0,
//            level: 1
//        )
//    }
//    
//    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
//        let gameManager = GameManager.shared
//        let entry = ComplicationEntry(
//            date: Date(),
//            realm: gameManager.getRealmShort(),
//            progressPct: Int(gameManager.getCurrentProgress() * 100),
//            level: gameManager.player.level
//        )
//        completion(entry)
//    }
//    
//    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
//        let gameManager = GameManager.shared
//        let currentDate = Date()
//        
//        // Create entries for the next few hours
//        var entries: [ComplicationEntry] = []
//        
//        // Current entry
//        let currentEntry = ComplicationEntry(
//            date: currentDate,
//            realm: gameManager.getRealmShort(),
//            progressPct: Int(gameManager.getCurrentProgress() * 100),
//            level: gameManager.player.level
//        )
//        entries.append(currentEntry)
//        
//        // Future entries (every 30 minutes)
//        for hourOffset in 1...4 {
//            let entryDate = Calendar.current.date(
//                byAdding: .minute,
//                value: hourOffset * 30,
//                to: currentDate
//            )!
//            
//            let entry = ComplicationEntry(
//                date: entryDate,
//                realm: gameManager.getRealmShort(),
//                progressPct: Int(gameManager.getCurrentProgress() * 100),
//                level: gameManager.player.level
//            )
//            entries.append(entry)
//        }
//        
//        // Set next refresh
//        let nextRefresh = Calendar.current.date(
//            byAdding: .minute,
//            value: Int(GameConstants.COMPLICATION_REFRESH_MINUTES),
//            to: currentDate
//        )!
//        
//        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
//        completion(timeline)
//    }
//}
//
//// MARK: - Complication Entry
//struct ComplicationEntry: TimelineEntry {
//    let date: Date
//    let realm: String
//    let progressPct: Int
//    let level: Int
//}
//
//// MARK: - Complication Views
//struct ComplicationView: View {
//    let entry: ComplicationEntry
//    
//    var body: some View {
//        ZStack {
//            // Background
//            Circle()
//                .fill(
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color(red: 0.2, green: 0.1, blue: 0.3),
//                            Color(red: 0.3, green: 0.2, blue: 0.4)
//                        ]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//            
//            VStack(spacing: 2) {
//                // Realm name
//                Text(entry.realm)
//                    .font(.system(size: 11, weight: .bold))
//                    .foregroundColor(.white)
//                
//                // Progress
//                Text("\(entry.progressPct)%")
//                    .font(.system(size: 9))
//                    .foregroundColor(.white.opacity(0.8))
//            }
//        }
//    }
//}
//
//// Circular complication
//struct CircularComplicationView: View {
//    let entry: ComplicationEntry
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(Color.white.opacity(0.3), lineWidth: 2)
//            
//            Circle()
//                .trim(from: 0, to: CGFloat(entry.progressPct) / 100.0)
//                .stroke(
//                    Color.green,
//                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
//                )
//                .rotationEffect(.degrees(-90))
//            
//            VStack(spacing: 1) {
//                Text(entry.realm)
//                    .font(.system(size: 9, weight: .bold))
//                    .foregroundColor(.white)
//                
//                Text("\(entry.progressPct)%")
//                    .font(.system(size: 7))
//                    .foregroundColor(.white.opacity(0.7))
//            }
//        }
//        .padding(4)
//    }
//}
//
//// Modular complication
//struct ModularComplicationView: View {
//    let entry: ComplicationEntry
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            // Icon
//            ZStack {
//                Circle()
//                    .fill(Color.purple.opacity(0.3))
//                    .frame(width: 24, height: 24)
//                
//                Text("仙")
//                    .font(.system(size: 12, weight: .bold))
//                    .foregroundColor(.white)
//            }
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(entry.realm)
//                    .font(.system(size: 12, weight: .semibold))
//                    .foregroundColor(.white)
//                
//                HStack(spacing: 4) {
//                    // Progress bar
//                    GeometryReader { geo in
//                        ZStack(alignment: .leading) {
//                            RoundedRectangle(cornerRadius: 2)
//                                .fill(Color.white.opacity(0.2))
//                            
//                            RoundedRectangle(cornerRadius: 2)
//                                .fill(Color.green)
//                                .frame(width: geo.size.width * CGFloat(entry.progressPct) / 100.0)
//                        }
//                    }
//                    .frame(height: 3)
//                    
//                    Text("\(entry.progressPct)%")
//                        .font(.system(size: 8))
//                        .foregroundColor(.white.opacity(0.6))
//                }
//            }
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//    }
//}
//
//// MARK: - Widget Configuration
//@main
//struct XiuxianComplication: Widget {
//    let kind: String = "XiuxianComplication"
//    
//    var body: some WidgetConfiguration {
//        StaticConfiguration(
//            kind: kind,
//            provider: ComplicationProvider()
//        ) { entry in
//            ComplicationView(entry: entry)
//        }
//        .configurationDisplayName("掌上修仙")
//        .description("显示当前修炼进度")
//        .supportedFamilies([
//            .accessoryCircular,
//            .accessoryCorner,
//            .accessoryInline,
//            .accessoryRectangular
//        ])
//    }
//}
//
//// MARK: - Helper Extensions
//extension GameManager {
//    func reloadComplications() {
//        WidgetCenter.shared.reloadAllTimelines()
//    }
//}
