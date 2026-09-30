//
//  PunchWidget.swift
//  PunchWidget
//
//  Created by Sunil Rajai on 16/09/26.
//

import WidgetKit
import SwiftUI

// MARK: - App Group shared storage
// Both the widget extension and the main Runner app have the same App Group:
// "group.com.hrmnewapp.taxhrm"
// Writing here from the widget IS possible (widget processes can write to their own
// shared container). The flag is read by the main app on foreground.
private let appGroupID = "group.com.hrmnewapp.taxhrm"
private let punchPendingKey = "widgetPunchTap"

// MARK: - Timeline Provider (Static — no configuration needed)
struct PunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> PunchEntry {
        PunchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PunchEntry) -> Void) {
        completion(PunchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PunchEntry>) -> Void) {
        // Single entry, never refreshed (static widget)
        let timeline = Timeline(entries: [PunchEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct PunchEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View
struct PunchWidgetEntryView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("PUNCH")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("Tap to open")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
        }
        // widgetURL: tapping anywhere on the widget opens taxhrm://punch in the main app.
        // The main app's AppDelegate handles this URL in application(_:open:url:options:).
        .widgetURL(URL(string: "taxhrm://punch"))
    }
}

// MARK: - Widget Definition
struct PunchWidget: Widget {
    let kind: String = "PunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PunchProvider()) { _ in
            if #available(iOS 17.0, *) {
                PunchWidgetEntryView()
                    .containerBackground(
                        Color(red: 24 / 255.0, green: 100 / 255.0, blue: 236 / 255.0),
                        for: .widget
                    )
            } else {
                PunchWidgetEntryView()
                    .background(Color(red: 24 / 255.0, green: 100 / 255.0, blue: 236 / 255.0))
            }
        }
        .configurationDisplayName("Punch Widget")
        .description("Tap to open the punch screen instantly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
// #Preview(as: .systemSmall) {
//     PunchWidget()
// } timeline: {
//     PunchEntry(date: .now)
// }
