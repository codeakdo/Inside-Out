import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let sharedContainer: ModelContainer = {
        do {
            let schema = Schema(versionedSchema: InsideOutSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: InsideOutMigrationPlan.self,
                configurations: [configuration]
            )
            if try container.mainContext.fetch(FetchDescriptor<DailyEntry>()).isEmpty {
                seedPreviewData(in: container.mainContext)
            }
            return container
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    static func makePreviewContainer() -> ModelContainer {
        do {
            let schema = Schema(versionedSchema: InsideOutSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: InsideOutMigrationPlan.self,
                configurations: [configuration]
            )
            seedPreviewData(in: container.mainContext)
            return container
        } catch {
            fatalError("Unable to create preview container: \(error)")
        }
    }

    private static func seedPreviewData(in context: ModelContext) {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)

        let samples: [[EmotionKind: Double]] = [
            [.joy: 65, .gratitude: 35],
            [.serenity: 55, .hope: 45],
            [.anxiety: 40, .hope: 30, .confidence: 30],
            [.love: 50, .gratitude: 20, .serenity: 30],
            [.sadness: 45, .loneliness: 25, .hope: 30],
            [.confidence: 50, .joy: 30, .gratitude: 20],
            [.serenity: 40, .love: 35, .joy: 25]
        ]

        let notes = [
            "Felt lighter after my walk and let myself enjoy the quiet.",
            "Protected my energy and moved a little slower.",
            "A noisy morning, but I found steadiness by afternoon.",
            "A sweet call reminded me I am loved.",
            "Missed people today, but stayed kind to myself.",
            "Showed up with more confidence than I expected.",
            "Trying to stay present and grateful for small things."
        ]

        for index in 0..<7 {
            let entry = DailyEntry(
                date: calendar.date(byAdding: .day, value: -index, to: base) ?? base,
                noteText: notes[index]
            )

            let emotionSet = samples[index]
            let total = emotionSet.values.reduce(0, +)
            for (kind, rawValue) in emotionSet {
                let record = MoodEmotionRecord(kind: kind, rawValue: rawValue, percentage: (rawValue / total) * 100)
                record.entry = entry
                entry.emotions.append(record)
                context.insert(record)
            }

            if index % 2 == 0 {
                let memory = MemoryRecord(
                    title: index == 0 ? "Golden hour tea" : "Small bright moment",
                    bodyText: "A tiny detail worth keeping close from the day.",
                    tag: index == 0 ? "#ritual" : "#softness",
                    tagsRaw: index == 0 ? "#ritual #evening" : "#softness #archive"
                )
                memory.entry = entry
                entry.memories.append(memory)
                context.insert(memory)
            }

            let thought = ThoughtEntry(
                text: notes[index],
                tagsRaw: index == 0 ? "#gratitude #glow" : "#reflect #gentle",
                isPinned: true
            )
            thought.entry = entry
            entry.thoughts.append(thought)
            context.insert(thought)

            context.insert(entry)
        }

        try? context.save()
    }
}
