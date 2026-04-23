import SwiftUI
import WidgetKit

struct InsideOutWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedMoodSnapshot
}

struct InsideOutWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> InsideOutWidgetEntry {
        InsideOutWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (InsideOutWidgetEntry) -> Void) {
        completion(InsideOutWidgetEntry(date: .now, snapshot: SharedMoodSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InsideOutWidgetEntry>) -> Void) {
        let entry = InsideOutWidgetEntry(date: .now, snapshot: SharedMoodSnapshotStore.load())
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct InsideOutMoodWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InsideOutMoodWidget", provider: InsideOutWidgetProvider()) { entry in
            InsideOutWidgetView(entry: entry)
                .containerBackground(.white.gradient, for: .widget)
        }
        .configurationDisplayName("Inside Out")
        .description("See today's mood orb and dominant emotion.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct InsideOutWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: InsideOutWidgetEntry

    private var presentation: SharedMoodPresentation {
        SharedMoodRenderer.presentation(for: entry.snapshot)
    }

    var body: some View {
        switch family {
        case .systemSmall:
            VStack {
                Spacer()
                WidgetOrbView(presentation: presentation, size: 92)
                Spacer()
            }
        case .systemMedium:
            HStack(spacing: 16) {
                WidgetOrbView(presentation: presentation, size: 104)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's mood")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(presentation.dominantEmotion)
                        .font(.headline)
                    Text(presentation.hideThoughts ? "Unlock to see" : (presentation.thoughtPreview ?? "No thought saved yet"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
        default:
            HStack(spacing: 16) {
                WidgetOrbView(presentation: presentation, size: 116)
                VStack(alignment: .leading, spacing: 10) {
                    Text(presentation.dominantEmotion)
                        .font(.headline)
                    ForEach(presentation.emotions.prefix(4)) { emotion in
                        HStack {
                            Circle()
                                .fill(Color(hex: emotion.colorHex))
                                .frame(width: 10, height: 10)
                            Text(emotion.name)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(emotion.percentage.rounded()))%")
                                .font(.caption.monospacedDigit())
                        }
                    }
                    if presentation.hideThoughts {
                        Text("Unlock to see")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let thoughtPreview = presentation.thoughtPreview {
                        Text(thoughtPreview)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

private struct WidgetOrbView: View {
    let presentation: SharedMoodPresentation
    let size: CGFloat

    var body: some View {
        SharedOrbCore(presentation: presentation, size: size, showGlow: true)
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
