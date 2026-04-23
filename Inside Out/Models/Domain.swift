import Foundation
import SwiftUI

enum EntryVisibility: String, Codable, CaseIterable, Identifiable {
    case privateEntry = "private"
    case friends
    case publicEntry = "public"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privateEntry: "Private"
        case .friends: "Friends"
        case .publicEntry: "Public"
        }
    }
}

enum EmotionCategory: String, Codable, CaseIterable, Identifiable {
    case positive
    case negative

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum EmotionKind: String, Codable, CaseIterable, Identifiable {
    case joy
    case serenity
    case love
    case confidence
    case hope
    case sadness
    case anxiety
    case anger
    case loneliness
    case gratitude

    var id: String { rawValue }

    var name: String {
        switch self {
        case .joy: "Joy"
        case .serenity: "Serenity"
        case .love: "Love"
        case .confidence: "Confidence"
        case .hope: "Hope"
        case .sadness: "Sadness"
        case .anxiety: "Anxiety"
        case .anger: "Anger"
        case .loneliness: "Loneliness"
        case .gratitude: "Gratitude"
        }
    }

    var category: EmotionCategory {
        switch self {
        case .sadness, .anxiety, .anger, .loneliness:
            .negative
        default:
            .positive
        }
    }

    var color: Color {
        switch self {
        case .joy: Color(hex: "#F7C76D")
        case .serenity: Color(hex: "#9ED9D5")
        case .love: Color(hex: "#F39AA8")
        case .confidence: Color(hex: "#E6A96A")
        case .hope: Color(hex: "#C3B3F4")
        case .sadness: Color(hex: "#7AA6E8")
        case .anxiety: Color(hex: "#96A3C8")
        case .anger: Color(hex: "#ED8770")
        case .loneliness: Color(hex: "#A896C8")
        case .gratitude: Color(hex: "#A6D99B")
        }
    }

    var description: String {
        switch self {
        case .joy: "Bright, energized, uplifted."
        case .serenity: "Grounded, soft, unhurried."
        case .love: "Connected, warm, open-hearted."
        case .confidence: "Capable, centered, assured."
        case .hope: "Looking forward with trust."
        case .sadness: "Tender, low, reflective."
        case .anxiety: "Restless, uneasy, overactive."
        case .anger: "Activated, sharp, protective."
        case .loneliness: "Distant, quiet, missing closeness."
        case .gratitude: "Thankful, receptive, appreciative."
        }
    }
}

struct EmotionDisplay: Identifiable, Hashable {
    let kind: EmotionKind
    var rawValue: Double
    var percentage: Double

    var id: EmotionKind { kind }
    var name: String { kind.name }
    var color: Color { kind.color }
    var category: EmotionCategory { kind.category }
    var normalizedShare: Double { percentage / 100 }
    var formattedPercentage: String { "\(Int(percentage.rounded()))%" }
}

enum RootTab: Hashable {
    case home
    case moods
    case thoughts
    case memories
    case history
    case insights
}

enum DashboardSegment: String, CaseIterable, Identifiable {
    case memories = "Memories"
    case moods = "My Moods"
    case thoughts = "Thoughts"

    var id: String { rawValue }
}

struct WeeklyOrbDay: Identifiable {
    let date: Date
    let entry: DailyEntry?

    var id: Date { date }
}

struct EmotionSummary: Identifiable {
    let kind: EmotionKind
    let total: Double

    var id: EmotionKind { kind }
}

struct ThoughtComposerState {
    var text = ""
    var tags = ""
    var editingThoughtID: UUID?

    var isEditing: Bool { editingThoughtID != nil }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppTheme {
    static let background = Color.dynamic(light: "#FCFAF7", dark: "#1A1A1A")
    static let secondaryBackground = Color.dynamic(light: "#F6F0EB", dark: "#121212")
    static let card = Color(UIColor { traitCollection -> UIColor in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#242424").withAlphaComponent(0.98)
            : UIColor(hex: "#FFFFFF").withAlphaComponent(0.93)
    })

    static let ink = Color.dynamic(light: "#5D514B", dark: "#F2F2F7")
    static let mutedInk = Color.dynamic(light: "#8F817A", dark: "#C7C7CC")
    static let rose = Color.dynamic(light: "#D38D95", dark: "#FF7A8A")
    static let mist = Color.dynamic(light: "#E8DDD6", dark: "#2C2C2E")
    static let gold = Color.dynamic(light: "#D5B57C", dark: "#FFD640")
    static let stroke = Color.dynamic(light: "#EADFD6", dark: "#3A3A3C")
    static func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension Color {
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection -> UIColor in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

extension Date {
    var dayTitle: String {
        formatted(.dateTime.weekday(.abbreviated))
    }

    var dayNumberTitle: String {
        formatted(.dateTime.day())
    }

    var monthDayTitle: String {
        formatted(.dateTime.month(.wide).day().year())
    }

    var shortMonthDay: String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    var startOfDayValue: Date {
        Calendar.current.startOfDay(for: self)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
