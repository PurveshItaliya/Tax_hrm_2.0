//
//  PunchWidget.swift
//  PunchWidget
//
//  Created by Sunil Rajai on 16/09/26.
//

import WidgetKit
import SwiftUI

// MARK: - App Group shared storage
private let appGroupID = "group.com.hrmnewapp.taxhrm"
private let punchPendingKey = "widgetPunchTap"

// MARK: - Timeline Provider
struct PunchProvider: TimelineProvider {
    private func getSettingsEntry() -> PunchEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let color = defaults?.string(forKey: "widget_color") ?? "transparent"
        let transparency = defaults?.double(forKey: "widget_transparency") ?? 0.70
        let darkness = defaults?.double(forKey: "widget_darkness") ?? 0.20
        let blur = defaults?.double(forKey: "widget_blur") ?? 24.0
        return PunchEntry(date: Date(), color: color, transparency: transparency, darkness: darkness, blur: blur)
    }

    func placeholder(in context: Context) -> PunchEntry {
        getSettingsEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PunchEntry) -> Void) {
        completion(getSettingsEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PunchEntry>) -> Void) {
        let entry = getSettingsEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct PunchEntry: TimelineEntry {
    let date: Date
    let color: String
    let transparency: Double
    let darkness: Double
    let blur: Double
}

// MARK: - Widget View (Transparent Liquid Glass with Live Customization)
struct PunchWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PunchEntry

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 32
        case .systemMedium:
            return 40
        case .systemLarge, .systemExtraLarge:
            return 56
        default:
            return 32
        }
    }

    private var textColor: Color {
        entry.color == "white" ? Color(red: 15 / 255.0, green: 23 / 255.0, blue: 42 / 255.0) : .white
    }

    private var rimStrokeColor: Color {
        switch entry.color {
        case "white":
            return Color.black.opacity(0.12)
        case "black":
            return Color.white.opacity(0.20)
        case "blue":
            return Color.white.opacity(0.35)
        default:
            return Color.white.opacity(0.70)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch entry.color {
        case "black":
            // Pure jet dark black (never grey!) with subtle top edge glass highlight
            ZStack {
                Color.black
                LinearGradient(
                    colors: [Color.white.opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        case "blue":
            // Rich dark primary theme blue matching app (#104EC8 to #0A368A)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 16 / 255.0, green: 78 / 255.0, blue: 200 / 255.0),
                        Color(red: 10 / 255.0, green: 54 / 255.0, blue: 138 / 255.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [Color.white.opacity(0.25), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            }
        case "white":
            Color.white
        case "transparent":
        default:
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                if entry.blur > 0 {
                    Color.white.opacity(min((entry.blur / 50.0) * 0.25, 0.35))
                }
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.35),
                        Color.white.opacity(0.12),
                        Color.clear,
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    var body: some View {
        ZStack {
            // 1. Dedicated Theme Background
            backgroundView

            // 2. Inner Specular Glass Rim / Border
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(rimStrokeColor, lineWidth: 1.5)
                .padding(3)

            // 3. Centered "PUNCH" text only bold with theme-aware high contrast
            Text("PUNCH")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .tracking(2.5)
                .foregroundColor(textColor)
                .shadow(color: entry.color == "white" ? Color.clear : Color.black.opacity(0.45), radius: 8, x: 0, y: 2)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // widgetURL: tapping anywhere on the widget triggers punch in the main app
        .widgetURL(URL(string: "taxhrm://punch"))
    }
}

// MARK: - Widget Definition
struct PunchWidget: Widget {
    let kind: String = "PunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PunchProvider()) { entry in
            if #available(iOS 17.0, *) {
                PunchWidgetEntryView(entry: entry)
                    .containerBackground(.ultraThinMaterial, for: .widget)
            } else {
                PunchWidgetEntryView(entry: entry)
                    .background(.ultraThinMaterial)
            }
        }
        .configurationDisplayName("Punch Widget")
        .description("Tap to open the punch screen instantly.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}

private extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}
