import Foundation
import SwiftUI
import SwiftData
import UIKit
import WidgetKit
import UserNotifications

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var selectedRootTab: RootTab = .home
    @Published var selectedDashboardSegment: DashboardSegment = .moods
    @Published var selectedDate: Date = .now.startOfDayValue
    @Published var emotionFilter: EmotionCategory? = nil
    @Published var isSaving = false
    @Published var showingMemoryComposer = false
    @Published var memoryTitle = ""
    @Published var memoryBody = ""
    @Published var memoryTag = ""
    @Published var thoughtComposer = ThoughtComposerState()
    @Published var historySearchText = ""
    @Published var selectedHistoryEntry: DailyEntry?
    @Published private(set) var orbAnimationTick: Double = 0

    @Published private(set) var entries: [DailyEntry] = []
    @Published private(set) var rawEmotionValues: [EmotionKind: Double] = [:]

    init() {
        EmotionKind.allCases.forEach { rawEmotionValues[$0] = 0 }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<23: return "Good evening"
        default: return "A gentle night"
        }
    }

    var currentEntry: DailyEntry? {
        entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
    }

    var currentEmotionDisplays: [EmotionDisplay] {
        let total = rawEmotionValues.values.reduce(0, +)
        return EmotionKind.allCases.compactMap { kind in
            let rawValue = rawEmotionValues[kind, default: 0]
            guard rawValue > 0.001 else { return nil }
            return EmotionDisplay(
                kind: kind,
                rawValue: rawValue,
                percentage: total > 0 ? (rawValue / total) * 100 : 0
            )
        }
        .sorted { $0.rawValue > $1.rawValue }
    }

    func emotionDisplays(for entry: DailyEntry?) -> [EmotionDisplay] {
        guard let entry else { return [] }
        return entry.emotions
            .map { EmotionDisplay(kind: $0.kind, rawValue: $0.rawValue, percentage: $0.percentage) }
            .sorted { $0.percentage > $1.percentage }
    }

    var filteredEmotions: [EmotionDisplay] {
        currentEmotionDisplays.filter { emotion in
            guard let emotionFilter else { return true }
            return emotion.category == emotionFilter
        }
    }

    var filteredEmotionKinds: [EmotionKind] {
        EmotionKind.allCases.filter { kind in
            guard let emotionFilter else { return true }
            return kind.category == emotionFilter
        }
    }

    var selectedDayMemories: [MemoryRecord] {
        (currentEntry?.memories ?? []).sorted(by: { $0.createdAt > $1.createdAt })
    }

    var selectedDayThoughts: [ThoughtEntry] {
        (currentEntry?.thoughts ?? [])
            .sorted {
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned && !$1.isPinned
                }
                return $0.createdAt > $1.createdAt
            }
    }

    var weeklyDays: [WeeklyOrbDay] {
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate.startOfDayValue)?.start.startOfDayValue ?? selectedDate.startOfDayValue
        return (0..<7).map { offset in
            let date = start.adding(days: offset).startOfDayValue
            let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
            return WeeklyOrbDay(date: date, entry: entry)
        }
    }

    var thoughtCharacterCount: Int {
        thoughtComposer.text.count
    }

    var hashtagSuggestions: [String] {
        let moodTags = currentEmotionDisplays.prefix(3).map { "#\($0.kind.rawValue)" }
        let defaults = ["#breathe", "#reflect", "#reset", "#gratitude", "#tinywins"]
        return Array(NSOrderedSet(array: moodTags + defaults)) as? [String] ?? defaults
    }

    var dominantEmotion: EmotionDisplay? {
        currentEmotionDisplays.first
    }

    var pinnedThought: ThoughtEntry? {
        selectedDayThoughts.first(where: \.isPinned)
    }

    var thoughtPreview: String? {
        SharedMoodRenderer.thoughtPreview(
            pinnedThought: pinnedThought?.text,
            fallbackThought: selectedDayThoughts.first?.text
        )
    }

    var filteredHistoryEntries: [DailyEntry] {
        let query = historySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            entry.thoughts.contains {
                $0.text.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            } ||
            entry.memories.contains {
                $0.title.lowercased().contains(query) ||
                $0.bodyText.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
    }

    var currentStreak: Int {
        let activeDates = Set(entries.filter(hasSavedContent(in:)).map(\.date).map(\.startOfDayValue))
        guard !activeDates.isEmpty else { return 0 }

        var streak = 0
        var cursor = Date.now.startOfDayValue
        while activeDates.contains(cursor) {
            streak += 1
            cursor = cursor.adding(days: -1)
        }
        return streak
    }

    var totalRecordedDays: Int {
        entries.filter(hasSavedContent(in:)).count
    }

    func personalizedGreeting(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? greeting : "\(greeting), \(trimmed)"
    }

    func refresh(context: ModelContext) {
        let descriptor = FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        entries = (try? context.fetch(descriptor)) ?? []
        hydrateDraftFromEntry()
        syncWidgetSnapshot()
    }

    func select(date: Date, context: ModelContext) {
        selectedDate = date.startOfDayValue
        refresh(context: context)
    }

    func updateEmotion(_ emotion: EmotionKind, to value: Double) {
        var newValues = rawEmotionValues
        newValues[emotion] = value
        rawEmotionValues = newValues
        orbAnimationTick += 1
        
        // Add light haptic for slider movement
        if Int(value) % 5 == 0 {
            AppTheme.triggerHaptic(.soft)
        }
    }

    func resetMoodDraft() {
        var newValues: [EmotionKind: Double] = [:]
        EmotionKind.allCases.forEach { newValues[$0] = 0 }
        rawEmotionValues = newValues
        orbAnimationTick += 1
        AppTheme.triggerHaptic(.soft)
    }

    func saveMood(context: ModelContext) {
        performSaveAnimation {
            let entry = entryForSelectedDate(context: context)
            let currentDisplays = currentEmotionDisplays
            let currentKinds = Set(currentDisplays.map { $0.kind })

            // 1. Update existing or add new
            for display in currentDisplays {
                if let existing = entry.emotions.first(where: { $0.kind == display.kind }) {
                    existing.rawValue = display.rawValue
                    existing.percentage = display.percentage
                } else {
                    let record = MoodEmotionRecord(
                        kind: display.kind,
                        rawValue: display.rawValue,
                        percentage: display.percentage
                    )
                    record.entry = entry
                    entry.emotions.append(record)
                    context.insert(record)
                }
            }

            // 2. Remove ones that are no longer in the blend
            for emotion in entry.emotions {
                if !currentKinds.contains(emotion.kind) {
                    // Note: We don't remove from array manually as SwiftData handles context.delete relationship cleanup
                    context.delete(emotion)
                }
            }

            entry.noteText = thoughtPreview ?? ""
            entry.updatedAt = .now
            persist(context: context)
        }
    }

    func addMemory(context: ModelContext) {
        let title = memoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = memoryBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else { return }

        performSaveAnimation {
            let entry = entryForSelectedDate(context: context)
            let tags = Array(Set(memoryTag.hashtagsExtracted() + memoryTag.tagTokens + body.hashtagsExtracted()))
            let memory = MemoryRecord(
                title: title,
                bodyText: body,
                tag: memoryTag.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                tagsRaw: tags.joined(separator: " ")
            )
            memory.entry = entry
            entry.memories.append(memory)
            entry.noteText = thoughtPreview ?? ""
            entry.updatedAt = .now
            context.insert(memory)
            persist(context: context)
            clearMemoryComposer()
            showingMemoryComposer = false
        }
    }

    func deleteMemory(_ memory: MemoryRecord, context: ModelContext) {
        context.delete(memory)
        currentEntry?.updatedAt = .now
        persist(context: context)
        triggerHaptic(.rigid)
    }

    func saveThought(context: ModelContext) {
        let text = thoughtComposer.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        performSaveAnimation {
            let entry = entryForSelectedDate(context: context)
            let tags = Array(Set(thoughtComposer.tags.hashtagsExtracted() + text.hashtagsExtracted() + thoughtComposer.tags.tagTokens))

            if let editingThoughtID = thoughtComposer.editingThoughtID,
               let existingThought = entry.thoughts.first(where: { $0.id == editingThoughtID }) {
                existingThought.text = text
                existingThought.tagsRaw = tags.joined(separator: " ")
            } else {
                let thought = ThoughtEntry(
                    text: text,
                    tagsRaw: tags.joined(separator: " "),
                    isPinned: entry.thoughts.isEmpty
                )
                thought.entry = entry
                entry.thoughts.append(thought)
                context.insert(thought)
            }

            entry.noteText = updatedThoughtPreview(for: entry) ?? ""
            entry.updatedAt = .now
            persist(context: context)
            clearThoughtComposer()
        }
    }

    func beginEditingThought(_ thought: ThoughtEntry) {
        thoughtComposer.text = thought.text
        thoughtComposer.tags = thought.tags.joined(separator: " ")
        thoughtComposer.editingThoughtID = thought.id
    }

    func cancelEditingThought() {
        clearThoughtComposer()
    }

    func deleteThought(_ thought: ThoughtEntry, context: ModelContext) {
        let entry = thought.entry
        context.delete(thought)
        entry?.noteText = updatedThoughtPreview(for: entry) ?? ""
        entry?.updatedAt = .now
        persist(context: context)
    }

    func togglePinned(_ thought: ThoughtEntry, context: ModelContext) {
        guard let entry = thought.entry else { return }
        for item in entry.thoughts {
            item.isPinned = item.id == thought.id ? !thought.isPinned : false
        }
        if !entry.thoughts.contains(where: \.isPinned), let newest = entry.thoughts.sorted(by: { $0.createdAt > $1.createdAt }).first {
            newest.isPinned = true
        }
        entry.noteText = updatedThoughtPreview(for: entry) ?? ""
        entry.updatedAt = .now
        persist(context: context)
    }

    func applySuggestion(_ hashtag: String) {
        if thoughtComposer.tags.isEmpty {
            thoughtComposer.tags = hashtag + " "
        } else if !thoughtComposer.tags.contains(hashtag) {
            thoughtComposer.tags += " " + hashtag
        }
        triggerHaptic(.light)
    }

    func applyMemoryTag(_ hashtag: String) {
        if memoryTag.isEmpty {
            memoryTag = hashtag + " "
        } else if !memoryTag.contains(hashtag) {
            memoryTag += " " + hashtag
        }
        triggerHaptic(.light)
    }

    func recordedDays(for days: Int) -> Int {
        let fromDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: .now.startOfDayValue) ?? .now
        return entries.filter { $0.date >= fromDate && hasSavedContent(in: $0) }.count
    }

    func emotionSummary(for days: Int) -> [EmotionSummary] {
        let fromDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: .now.startOfDayValue) ?? .now
        let bucket = entries
            .filter { $0.date >= fromDate }
            .flatMap(\.emotions)
            .reduce(into: [EmotionKind: Double]()) { partialResult, record in
                partialResult[record.kind, default: 0] += record.percentage
            }

        return bucket
            .map { EmotionSummary(kind: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    func positiveNegativeRatio(for days: Int) -> (positive: Double, negative: Double) {
        let fromDate = Calendar.current.date(byAdding: .day, value: -(days - 1), to: .now.startOfDayValue) ?? .now
        let records = entries.filter { $0.date >= fromDate }.flatMap(\.emotions)
        let positive = records.filter { $0.kind.category == .positive }.reduce(0) { $0 + $1.percentage }
        let negative = records.filter { $0.kind.category == .negative }.reduce(0) { $0 + $1.percentage }
        let total = max(positive + negative, 0.0001)
        return (positive / total, negative / total)
    }

    func hydrateDraftFromEntry() {
        var newValues: [EmotionKind: Double] = [:]
        EmotionKind.allCases.forEach { newValues[$0] = 0 }
        
        if let entry = currentEntry {
            for emotion in entry.emotions {
                newValues[emotion.kind] = emotion.rawValue
            }
        }
        rawEmotionValues = newValues
        clearThoughtComposer()
        orbAnimationTick += 1
    }

    func widgetSnapshot(for entry: DailyEntry?) -> SharedMoodSnapshot {
        let hideThoughts = UserDefaults(suiteName: AppGroupConfig.identifier)?.bool(forKey: AppGroupConfig.hideThoughtsKey) ?? false
        guard let entry else {
            return SharedMoodSnapshot(
                date: .now,
                dominantEmotion: "No mood saved",
                thoughtPreview: nil,
                emotions: [],
                hideThoughts: hideThoughts
            )
        }
        let emotions = entry.emotions.map {
            SharedMoodEmotion(
                kind: $0.rawKind,
                name: $0.name,
                colorHex: $0.hexColor,
                category: $0.rawCategory,
                percentage: $0.percentage
            )
        }
        let normalized = SharedMoodRenderer.normalize(emotions)

        return SharedMoodSnapshot(
            date: entry.date,
            dominantEmotion: normalized.first?.name ?? "No mood saved",
            thoughtPreview: hideThoughts ? nil : updatedThoughtPreview(for: entry),
            emotions: normalized,
            hideThoughts: hideThoughts
        )
    }

    func entryThoughtPreview(_ entry: DailyEntry?) -> String? {
        updatedThoughtPreview(for: entry)
    }

    func reminderDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }

    func updateReminder(enabled: Bool, time: Date) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "insideout.daily-reminder"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted == true else { return }

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = "Inside Out"
        content.body = "Take a quiet moment to blend today's mood."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func reloadWidgetSnapshot(context: ModelContext) {
        refresh(context: context)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func entryForSelectedDate(context: ModelContext) -> DailyEntry {
        if let currentEntry {
            return currentEntry
        }

        let entry = DailyEntry(date: selectedDate.startOfDayValue)
        context.insert(entry)
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        return entry
    }

    private func persist(context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("Failed to save Inside Out data: \(error.localizedDescription)")
        }
        refresh(context: context)
        syncWidgetSnapshot()
        WidgetCenter.shared.reloadAllTimelines()
        triggerHaptic(.medium)
    }

    private func performSaveAnimation(_ action: () -> Void) {
        isSaving = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            self?.isSaving = false
        }
    }

    private func clearMemoryComposer() {
        memoryTitle = ""
        memoryBody = ""
        memoryTag = ""
    }

    private func clearThoughtComposer() {
        thoughtComposer = ThoughtComposerState()
    }

    private func hasSavedContent(in entry: DailyEntry) -> Bool {
        !entry.emotions.isEmpty || !entry.thoughts.isEmpty || !entry.memories.isEmpty
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func syncWidgetSnapshot() {
        let todayEntry = entries.first(where: { Calendar.current.isDateInToday($0.date) })
        SharedMoodSnapshotStore.save(widgetSnapshot(for: todayEntry))
    }

    private func updatedThoughtPreview(for entry: DailyEntry?) -> String? {
        guard let entry else { return nil }
        let pinned = entry.thoughts.first(where: \.isPinned)?.text
        let fallback = entry.thoughts.sorted(by: { $0.createdAt > $1.createdAt }).first?.text
        return SharedMoodRenderer.thoughtPreview(pinnedThought: pinned, fallbackThought: fallback)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
