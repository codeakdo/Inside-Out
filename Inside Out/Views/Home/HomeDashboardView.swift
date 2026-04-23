import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: JournalViewModel
    let userName: String

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
                VStack(spacing: AppLayout.sectionSpacing) {
                    AppSectionHeader(
                        eyebrow: viewModel.personalizedGreeting(for: userName),
                        title: viewModel.selectedDate.monthDayTitle
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    heroSection

                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        DashboardMetricCard(
                            title: "Current streak",
                            value: "\(viewModel.currentStreak)",
                            detail: viewModel.currentStreak == 1 ? "day in your rhythm" : "days in your rhythm",
                            tint: AppTheme.gold,
                            symbol: "flame.fill"
                        )
                        DashboardMetricCard(
                            title: "Mood tones",
                            value: "\(viewModel.currentEmotionDisplays.count)",
                            detail: viewModel.currentEmotionDisplays.isEmpty ? "no blend saved yet" : "active emotions today",
                            tint: viewModel.dominantEmotion?.color ?? AppTheme.rose,
                            symbol: "circle.hexagongrid.fill"
                        )
                        DashboardMetricCard(
                            title: "Thoughts",
                            value: "\(viewModel.selectedDayThoughts.count)",
                            detail: viewModel.selectedDayThoughts.isEmpty ? "nothing written yet" : "notes saved today",
                            tint: AppTheme.rose,
                            symbol: "quote.bubble.fill"
                        )
                        DashboardMetricCard(
                            title: "Memories",
                            value: "\(viewModel.selectedDayMemories.count)",
                            detail: viewModel.selectedDayMemories.isEmpty ? "nothing archived yet" : "moments saved today",
                            tint: AppTheme.gold,
                            symbol: "heart.text.square.fill"
                        )
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Week at a glance")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            WeeklyOrbRow(days: viewModel.weeklyDays, selectedDate: viewModel.selectedDate) { date in
                                viewModel.select(date: date, context: modelContext)
                            }
                        }
                    }

                    SegmentedPicker(items: DashboardSegment.allCases, selection: $viewModel.selectedDashboardSegment)

                    dashboardSegmentContent
                }
                .safeAreaPadding(.top, 8)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh(context: modelContext)
        }
    }

    private var heroSection: some View {
        PremiumCard {
            VStack(spacing: 18) {
                HandwritingHeader(text: "Inside Out")

                OrbView(
                    emotions: viewModel.currentEmotionDisplays,
                    size: AppLayout.heroOrbSize,
                    isSubtle: true,
                    animationTick: viewModel.orbAnimationTick
                )
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Text(viewModel.dominantEmotion?.name ?? "A soft blank canvas")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)

                    Text(viewModel.dominantEmotion?.kind.description ?? "No mood blend saved yet for this day.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 258)

                    if let thoughtPreview = viewModel.thoughtPreview {
                        Text("“\(thoughtPreview)”")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink.opacity(0.82))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: 280)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var dashboardSegmentContent: some View {
        switch viewModel.selectedDashboardSegment {
        case .memories:
            PremiumCard {
                if viewModel.selectedDayMemories.isEmpty {
                    EmptyStateView(
                        title: "No memories yet",
                        subtitle: "Save one sweet detail from today to build your emotional archive.",
                        actionTitle: "Add a memory",
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                viewModel.selectedRootTab = .memories
                            }
                        }
                    )
                } else {
                    VStack(spacing: AppLayout.cardSpacing) {
                        ForEach(viewModel.selectedDayMemories.prefix(3)) { memory in
                            MemoryCardView(memory: memory)
                        }
                    }
                }
            }
        case .moods:
            PremiumCard {
                if viewModel.currentEmotionDisplays.isEmpty {
                    EmptyStateView(
                        title: "A soft blank canvas",
                        subtitle: "Start blending today's mood and let the orb quietly take shape.",
                        actionTitle: "Start blending today's mood",
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                viewModel.selectedRootTab = .moods
                            }
                        }
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.currentEmotionDisplays) { emotion in
                            EmotionRowView(emotion: emotion)
                        }
                    }
                }
            }
        case .thoughts:
            PremiumCard {
                if viewModel.selectedDayThoughts.isEmpty {
                    EmptyStateView(
                        title: "Write your daily thought",
                        subtitle: "A single sentence is enough. Let the note stay light and honest.",
                        actionTitle: "Write today's thought",
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                viewModel.selectedRootTab = .thoughts
                            }
                        }
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Thoughts")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        ForEach(viewModel.selectedDayThoughts.prefix(2)) { thought in
                            ThoughtCardView(thought: thought, onPin: { }, onEdit: { })
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeDashboardView(viewModel: JournalViewModel(), userName: "Ege")
            .modelContainer(PreviewData.makePreviewContainer())
    }
}
