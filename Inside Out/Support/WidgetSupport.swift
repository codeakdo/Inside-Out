import Foundation
import SwiftUI

enum AppGroupConfig {
    static let identifier = "group.com.egeakdo.InsideOut"
    static let snapshotKey = "insideout.widget.snapshot"
    static let hideThoughtsKey = "insideout.widget.hideThoughts"
}

struct SharedMoodEmotion: Codable, Hashable, Identifiable {
    let kind: String
    let name: String
    let colorHex: String
    let category: String
    let percentage: Double

    var id: String { kind }
}

struct SharedMoodSnapshot: Codable, Hashable {
    let date: Date
    let dominantEmotion: String
    let thoughtPreview: String?
    let emotions: [SharedMoodEmotion]
    let hideThoughts: Bool

    static let empty = SharedMoodSnapshot(date: .now, dominantEmotion: "No mood saved", thoughtPreview: nil, emotions: [], hideThoughts: false)
}

struct SharedMoodPresentation: Hashable {
    let dominantEmotion: String
    let thoughtPreview: String?
    let emotions: [SharedMoodEmotion]
    let gradientStops: [Gradient.Stop]
    let glowColors: [Color]
    let blobs: [SharedMoodBlob]
    let hideThoughts: Bool

    static let fallbackEmotion = SharedMoodEmotion(
        kind: "serenity",
        name: "Serenity",
        colorHex: "#9ED9D5",
        category: "positive",
        percentage: 100
    )
}

struct SharedMoodBlob: Hashable, Identifiable {
    let id: String
    let color: Color
    let offsetX: Double
    let offsetY: Double
    let radiusRatio: Double
    let blurRatio: Double
    let opacity: Double
}

enum SharedMoodRenderer {
    static func normalize(_ emotions: [SharedMoodEmotion]) -> [SharedMoodEmotion] {
        let filtered = emotions.filter { $0.percentage > 0.001 }
        guard !filtered.isEmpty else { return [SharedMoodPresentation.fallbackEmotion] }
        let total = filtered.reduce(0) { $0 + $1.percentage }
        guard total > 0.001 else { return [SharedMoodPresentation.fallbackEmotion] }

        return filtered
            .map {
                SharedMoodEmotion(
                    kind: $0.kind,
                    name: $0.name,
                    colorHex: $0.colorHex,
                    category: $0.category,
                    percentage: ($0.percentage / total) * 100
                )
            }
            .sorted { $0.percentage > $1.percentage }
    }

    static func gradientStops(for emotions: [SharedMoodEmotion]) -> [Gradient.Stop] {
        let normalized = normalize(emotions)
        var running = 0.0
        let stops = normalized.map { emotion in
            defer { running += emotion.percentage / 100 }
            return Gradient.Stop(color: sharedMoodColor(emotion.colorHex).opacity(0.92), location: running)
        }

        return stops + [Gradient.Stop(color: sharedMoodColor(normalized.last?.colorHex ?? "#9ED9D5").opacity(0.92), location: 1)]
    }

    static func presentation(for snapshot: SharedMoodSnapshot) -> SharedMoodPresentation {
        let normalized = normalize(snapshot.emotions)
        return SharedMoodPresentation(
            dominantEmotion: normalized.first?.name ?? snapshot.dominantEmotion,
            thoughtPreview: snapshot.hideThoughts ? nil : snapshot.thoughtPreview,
            emotions: normalized,
            gradientStops: gradientStops(for: normalized),
            glowColors: normalized.map { sharedMoodColor($0.colorHex) } + [Color.white.opacity(0.24)],
            blobs: blobs(for: normalized),
            hideThoughts: snapshot.hideThoughts
        )
    }

    static func thoughtPreview(pinnedThought: String?, fallbackThought: String?) -> String? {
        let pinned = pinnedThought?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let pinned, !pinned.isEmpty { return pinned }

        let fallback = fallbackThought?.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback?.isEmpty == false ? fallback : nil
    }

    static func blobs(for emotions: [SharedMoodEmotion]) -> [SharedMoodBlob] {
        let normalized = normalize(emotions)
        let anchors: [(Double, Double)] = [
            (-0.18, -0.16),
            (0.22, -0.14),
            (0.20, 0.20),
            (-0.20, 0.22),
            (0.0, 0.01),
            (-0.02, -0.28),
            (0.28, 0.02),
            (-0.28, 0.04),
            (0.05, 0.30),
            (-0.06, -0.33)
        ]

        return normalized.enumerated().map { index, emotion in
            let anchor = anchors[index % anchors.count]
            let share = emotion.percentage / 100
            let xSeed = deterministicSeed(for: emotion.kind, salt: 17)
            let ySeed = deterministicSeed(for: emotion.kind, salt: 43)
            let sizeSeed = deterministicSeed(for: emotion.kind, salt: 91)

            // Dynamic spread refined for calmer, organic fluidity
            let spread = 0.75 + (share * 0.25)
            let baseOffsetX = anchor.0 * spread
            let baseOffsetY = anchor.1 * spread

            return SharedMoodBlob(
                id: emotion.kind,
                color: sharedMoodColor(emotion.colorHex),
                offsetX: clamped(baseOffsetX + ((xSeed - 0.5) * 0.02), min: -0.32, max: 0.32),
                offsetY: clamped(baseOffsetY + ((ySeed - 0.5) * 0.02), min: -0.32, max: 0.32),
                radiusRatio: min(0.52, 0.18 + (share * 0.3) + (sizeSeed * 0.02)),
                blurRatio: 0.09 + (share * 0.04),
                opacity: max(0.66, 0.84 - (Double(index) * 0.05))
            )
        }
    }
}

struct SharedOrbCore: View {
    let presentation: SharedMoodPresentation
    let size: CGFloat
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: presentation.glowColors,
                            center: .center,
                            startRadius: size * 0.08,
                            endRadius: size * 0.68
                        )
                    )
                    .blur(radius: size * 0.12)
                    .frame(width: size * 1.08, height: size * 1.08)
            }

            Circle()
                .fill(.white.opacity(0.52))
                .frame(width: size, height: size)
                .blur(radius: size * 0.06)

            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: canvasSize)
                let ellipse = Path(ellipseIn: rect)

                context.clip(to: ellipse)
                context.fill(
                    ellipse,
                    with: .linearGradient(
                        Gradient(stops: presentation.gradientStops),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    )
                )

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: rect.width * 0.12))
                    layer.fill(
                        Path(ellipseIn: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)),
                        with: .radialGradient(
                            Gradient(colors: [Color.white.opacity(0.42), Color.clear]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 12,
                            endRadius: rect.width / 2
                        )
                    )
                }

                for blob in presentation.blobs {
                    let radius = rect.width * blob.radiusRatio
                    let x = rect.midX + (rect.width * blob.offsetX)
                    let y = rect.midY + (rect.height * blob.offsetY)
                    let circle = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)

                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: rect.width * blob.blurRatio))
                        layer.fill(
                            Path(ellipseIn: circle),
                            with: .color(blob.color.opacity(blob.opacity))
                        )
                    }
                }
            }
            .frame(width: size, height: size)
            .mask(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.56), lineWidth: 1.2)
            }
        }
        .frame(width: size, height: size)
    }
}

enum SharedMoodSnapshotStore {
    static func save(_ snapshot: SharedMoodSnapshot) {
        guard
            let defaults = UserDefaults(suiteName: AppGroupConfig.identifier),
            let data = try? JSONEncoder().encode(snapshot)
        else { return }

        defaults.set(data, forKey: AppGroupConfig.snapshotKey)
    }

    static func load() -> SharedMoodSnapshot {
        guard
            let defaults = UserDefaults(suiteName: AppGroupConfig.identifier),
            let data = defaults.data(forKey: AppGroupConfig.snapshotKey),
            let snapshot = try? JSONDecoder().decode(SharedMoodSnapshot.self, from: data)
        else { return .empty }

        return snapshot
    }
}

private func sharedMoodColor(_ hex: String) -> Color {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)

    return Color(
        .sRGB,
        red: Double((value >> 16) & 0xFF) / 255,
        green: Double((value >> 8) & 0xFF) / 255,
        blue: Double(value & 0xFF) / 255,
        opacity: 1
    )
}

private func deterministicSeed(for string: String, salt: UInt64) -> Double {
    let hash = string.unicodeScalars.reduce(salt) { partial, scalar in
        ((partial * 31) + UInt64(scalar.value)) % 10_000
    }
    return Double(hash) / 10_000
}

private func clamped(_ value: Double, min lowerBound: Double, max upperBound: Double) -> Double {
    Swift.min(upperBound, Swift.max(lowerBound, value))
}
