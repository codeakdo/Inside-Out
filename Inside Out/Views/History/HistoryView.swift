import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: JournalViewModel

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    AppSectionHeader(
                        eyebrow: "History",
                        title: "Your emotional timeline"
                    )

                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        DashboardMetricCard(
                            title: "Journaled days",
                            value: "\(viewModel.totalRecordedDays)",
                            detail: "days with a saved mood, thought, or memory",
                            tint: AppTheme.gold,
                            symbol: "calendar.badge.clock"
                        )
                        DashboardMetricCard(
                            title: "Current streak",
                            value: "\(viewModel.currentStreak)",
                            detail: viewModel.currentStreak == 1 ? "day in a row" : "days in a row",
                            tint: AppTheme.rose,
                            symbol: "flame.fill"
                        )
                    }

                    PremiumSearchField(text: $viewModel.historySearchText, prompt: "Search thoughts and memories")

                    if viewModel.filteredHistoryEntries.isEmpty {
                        PremiumCard {
                            EmptyStateView(
                                title: viewModel.historySearchText.isEmpty ? "No entries yet" : "No results found",
                                subtitle: viewModel.historySearchText.isEmpty ? "Your saved days will appear here with their mood orb previews." : "Try a softer keyword or search for a hashtag you used."
                            )
                        }
                    } else {
                        LazyVStack(spacing: AppLayout.cardSpacing) {
                            ForEach(viewModel.filteredHistoryEntries) { entry in
                                Button {
                                    viewModel.selectedHistoryEntry = entry
                                } label: {
                                    PremiumCard {
                                        HStack(spacing: 14) {
                                            OrbView(
                                                emotions: viewModel.emotionDisplays(for: entry),
                                                size: 68,
                                                showGlow: false
                                            )

                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(entry.date.monthDayTitle)
                                                    .font(.headline)
                                                    .foregroundStyle(AppTheme.ink)
                                                Text(viewModel.entryThoughtPreview(entry) ?? "No thought saved")
                                                    .font(.subheadline)
                                                    .foregroundStyle(AppTheme.mutedInk)
                                                    .lineLimit(2)
                                                HStack(spacing: 10) {
                                                    Text("\(entry.thoughts.count) thoughts")
                                                    Text("\(entry.memories.count) memories")
                                                    if let dominantEmotion = viewModel.emotionDisplays(for: entry).first?.name {
                                                        Text(dominantEmotion)
                                                    }
                                                }
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.mutedInk)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .safeAreaPadding(.top, 8)
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.selectedHistoryEntry) { entry in
            HistoryDetailView(entry: entry)
        }
        .onAppear {
            viewModel.refresh(context: modelContext)
        }
    }
}

private struct HistoryDetailView: View {
    let entry: DailyEntry
    @State private var shareImage: UIImage?
    @State private var shareURL: URL?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppLayout.sectionSpacing) {
                    PremiumCard {
                        VStack(spacing: 16) {
                            Text(entry.date.monthDayTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            OrbView(
                                emotions: entryEmotionDisplays,
                                size: AppLayout.detailOrbSize
                            )
                            if let dominantEmotion = entryEmotionDisplays.first?.name {
                                Text(dominantEmotion)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.mutedInk)
                            }

                            HStack(spacing: 10) {
                                Label("\(entryThoughts.count) thoughts", systemImage: "quote.bubble")
                                Label("\(entry.memories.count) memories", systemImage: "heart.text.square")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Thoughts")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                Spacer()
                                if let shareURL, let shareImage {
                                    ShareLink(
                                        item: shareURL,
                                        preview: SharePreview("Inside Out", image: Image(uiImage: shareImage))
                                    ) {
                                        Label("Share Card", systemImage: "square.and.arrow.up")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(AppTheme.rose)
                                }
                            }
                            if entryThoughts.isEmpty {
                                Text("No thought recorded for this day.")
                                    .foregroundStyle(AppTheme.ink.opacity(0.88))
                            } else {
                                ForEach(entryThoughts) { thought in
                                    ThoughtCardView(thought: thought, onPin: { }, onEdit: { })
                                }
                            }
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood Breakdown")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            ForEach(entryEmotionDisplays) { emotion in
                                EmotionRowView(
                                    emotion: emotion
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        CardSectionTitle(
                            title: "Memories",
                            subtitle: entry.memories.isEmpty ? "No memory was attached to this day yet." : "Saved moments that stayed with this emotional blend."
                        )

                        if entry.memories.isEmpty {
                            PremiumCard {
                                EmptyStateView(
                                    title: "No memories saved",
                                    subtitle: "This day holds a mood and thoughts, but no standalone memory card yet."
                                )
                            }
                        } else {
                            ForEach(entry.memories.sorted(by: { $0.createdAt > $1.createdAt })) { memory in
                                MemoryCardView(memory: memory)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            shareImage = renderShareImage()
            shareURL = makeShareURL(from: shareImage)
        }
    }

    private var entryEmotionDisplays: [EmotionDisplay] {
        entry.emotions
            .map { EmotionDisplay(kind: $0.kind, rawValue: $0.rawValue, percentage: $0.percentage) }
            .sorted { $0.percentage > $1.percentage }
    }

    private var entryThoughts: [ThoughtEntry] {
        entry.thoughts.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private var entryThoughtPreview: String? {
        let pinned = entryThoughts.first(where: \.isPinned)?.text
        let fallback = entryThoughts.first?.text
        return SharedMoodRenderer.thoughtPreview(pinnedThought: pinned, fallbackThought: fallback)
    }

    private func renderShareImage() -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareableMoodCardView(
                date: entry.date,
                emotions: entryEmotionDisplays,
                dominantEmotion: entryEmotionDisplays.first?.name ?? "Softly held",
                thoughtPreview: entryThoughtPreview
            )
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func makeShareURL(from image: UIImage?) -> URL? {
        guard let data = image?.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("insideout-\(entry.date.timeIntervalSince1970).png")
        try? data.write(to: url, options: .atomic)
        return url
    }
}

#Preview {
    NavigationStack {
        HistoryView(viewModel: JournalViewModel())
            .modelContainer(PreviewData.makePreviewContainer())
    }
}
