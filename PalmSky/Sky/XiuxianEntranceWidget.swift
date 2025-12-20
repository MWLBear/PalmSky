//
//  XiuxianEntranceWidget.swift
//  SkyExtension
//
//  Created by mac on 12/18/25.
//

import WidgetKit
import SwiftUI

struct EntranceEntry: TimelineEntry {
    let date: Date
}

struct EntranceProvider: TimelineProvider {
    func placeholder(in context: Context) -> EntranceEntry {
        EntranceEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EntranceEntry) -> Void) {
        completion(EntranceEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntranceEntry>) -> Void) {
        let entry = EntranceEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct XiuxianEntranceView: View {
    var body: some View {
        ZStack {
          
          AccessoryWidgetBackground()
          
          Image("TaiChi2")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .unredacted()
            .widgetAccentable()
            .padding()
         
        }
    }
}

struct XiuxianEntranceWidget: Widget {
    let kind = "XiuxianEntrance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EntranceProvider()) { _ in
            XiuxianEntranceView()
        }
        .configurationDisplayName("修仙入口")
        .description("八卦在手，直入修行")
        .supportedFamilies([.accessoryCircular])
    }
}
