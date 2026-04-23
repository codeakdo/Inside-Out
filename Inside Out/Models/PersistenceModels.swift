import Foundation
import SwiftData

enum InsideOutSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, MoodEmotionRecord.self, MemoryRecord.self, ThoughtEntry.self]
    }

    @Model
    final class DailyEntry {
        var date: Date
        var noteText: String
        var ownerId: String?
        var visibilityRaw: String
        var sharedWithRaw: String
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \MoodEmotionRecord.entry)
        var emotions: [MoodEmotionRecord]

        @Relationship(deleteRule: .cascade, inverse: \MemoryRecord.entry)
        var memories: [MemoryRecord]

        @Relationship(deleteRule: .cascade, inverse: \ThoughtEntry.entry)
        var thoughts: [ThoughtEntry]

        init(
            date: Date,
            noteText: String = "",
            ownerId: String? = nil,
            visibilityRaw: String = EntryVisibility.privateEntry.rawValue,
            sharedWithRaw: String = "",
            createdAt: Date = .now,
            updatedAt: Date = .now,
            emotions: [MoodEmotionRecord] = [],
            memories: [MemoryRecord] = [],
            thoughts: [ThoughtEntry] = []
        ) {
            self.date = date
            self.noteText = noteText
            self.ownerId = ownerId
            self.visibilityRaw = visibilityRaw
            self.sharedWithRaw = sharedWithRaw
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.emotions = emotions
            self.memories = memories
            self.thoughts = thoughts
        }

        var visibility: EntryVisibility {
            get { EntryVisibility(rawValue: visibilityRaw) ?? .privateEntry }
            set { visibilityRaw = newValue.rawValue }
        }

        var sharedWith: [String] {
            get {
                sharedWithRaw
                    .split(separator: ",")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            set {
                sharedWithRaw = newValue.joined(separator: ",")
            }
        }
    }

    @Model
    final class MoodEmotionRecord {
        var id: UUID
        var name: String
        var rawKind: String
        var rawCategory: String
        var hexColor: String
        var rawValue: Double
        var percentage: Double
        var createdAt: Date
        var entry: DailyEntry?

        init(kind: EmotionKind, rawValue: Double, percentage: Double, createdAt: Date = .now) {
            self.id = UUID()
            self.name = kind.name
            self.rawKind = kind.rawValue
            self.rawCategory = kind.category.rawValue
            self.hexColor = kind.hexString
            self.rawValue = rawValue
            self.percentage = percentage
            self.createdAt = createdAt
        }

        var kind: EmotionKind {
            EmotionKind(rawValue: rawKind) ?? .serenity
        }
    }

    @Model
    final class ThoughtEntry {
        var id: UUID
        var text: String
        var createdAt: Date
        var tagsRaw: String
        var isPinned: Bool
        var entry: DailyEntry?

        init(
            text: String,
            createdAt: Date = .now,
            tagsRaw: String = "",
            isPinned: Bool = false
        ) {
            self.id = UUID()
            self.text = text
            self.createdAt = createdAt
            self.tagsRaw = tagsRaw
            self.isPinned = isPinned
        }

        var tags: [String] {
            get { tagsRaw.tagTokens }
            set { tagsRaw = newValue.joined(separator: " ") }
        }
    }

    @Model
    final class MemoryRecord {
        var id: UUID
        var title: String
        var bodyText: String
        var tag: String?
        var tagsRaw: String
        var createdAt: Date
        var entry: DailyEntry?

        init(
            title: String,
            bodyText: String,
            tag: String? = nil,
            tagsRaw: String = "",
            createdAt: Date = .now
        ) {
            self.id = UUID()
            self.title = title
            self.bodyText = bodyText
            self.tag = tag
            self.tagsRaw = tagsRaw
            self.createdAt = createdAt
        }

        var tags: [String] {
            let explicit = tagsRaw.tagTokens
            let optionalTag = tag?.tagTokens ?? []
            return Array(Set(explicit + optionalTag))
        }
    }
}

enum InsideOutMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [InsideOutSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

typealias DailyEntry = InsideOutSchemaV1.DailyEntry
typealias MoodEmotionRecord = InsideOutSchemaV1.MoodEmotionRecord
typealias ThoughtEntry = InsideOutSchemaV1.ThoughtEntry
typealias MemoryRecord = InsideOutSchemaV1.MemoryRecord

extension EmotionKind {
    var hexString: String {
        switch self {
        case .joy: "#F7C76D"
        case .serenity: "#9ED9D5"
        case .love: "#F39AA8"
        case .confidence: "#E6A96A"
        case .hope: "#C3B3F4"
        case .sadness: "#7AA6E8"
        case .anxiety: "#96A3C8"
        case .anger: "#ED8770"
        case .loneliness: "#A896C8"
        case .gratitude: "#A6D99B"
        }
    }
}

extension String {
    var tagTokens: [String] {
        split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" })
            .map(String.init)
            .filter { $0.hasPrefix("#") || !$0.isEmpty }
            .map { $0.hasPrefix("#") ? $0.lowercased() : "#\($0.lowercased())" }
    }

    func hashtagsExtracted() -> [String] {
        let pattern = /#[A-Za-z0-9_]+/
        return matches(of: pattern).map { String($0.output).lowercased() }
    }
}
