import SwiftUI
import SwiftData

struct MyMoodsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: JournalViewModel
    @State private var showBlendInfo = false

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var currentBalance: (positive: Int, negative: Int) {
        guard !viewModel.currentEmotionDisplays.isEmpty else { return (0, 0) }
        let positive = viewModel.currentEmotionDisplays
            .filter { $0.category == .positive }
            .reduce(0.0) { $0 + $1.percentage }
        let negative = max(0, 100 - positive)
        return (Int(positive.rounded()), Int(negative.rounded()))
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    AppSectionHeader(
                        eyebrow: "Mood blend",
                        title: viewModel.selectedDate.shortMonthDay
                    )

                    PremiumCard {
                        VStack(spacing: 14) {
                            OrbView(
                                emotions: viewModel.currentEmotionDisplays,
                                size: AppLayout.showcaseOrbSize,
                                animationTick: viewModel.orbAnimationTick
                            )
                            .overlay(alignment: .bottom) {
                                HStack(spacing: 8) {
                                    Text("Live blend")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(AppTheme.mutedInk)
                                    
                                    Button {
                                        showBlendInfo = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.rose)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(AppTheme.secondaryBackground.opacity(0.92)))
                                .offset(y: 12)
                            }
                            .padding(.bottom, 20)

                            if viewModel.currentEmotionDisplays.isEmpty {
                                EmptyStateView(title: "Start with a feeling", subtitle: "Move the sliders below and watch your orb gently transform.")
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.filteredEmotions.prefix(4)) { emotion in
                                        EmotionRowView(emotion: emotion)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .alert("Understanding the Blend", isPresented: $showBlendInfo) {
                        Button("Got it", role: .cancel) { }
                    } message: {
                        Text("Percentages represent the relative share of each emotion in your total mood blend. Adjusting one slider naturally shifts the contribution of others to maintain a balanced emotional snapshot.")
                    }

                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        DashboardMetricCard(
                            title: "Active tones",
                            value: "\(viewModel.currentEmotionDisplays.count)",
                            detail: viewModel.currentEmotionDisplays.isEmpty ? "start with one feeling" : "emotions in this blend",
                            tint: viewModel.dominantEmotion?.color ?? AppTheme.rose,
                            symbol: "slider.horizontal.3"
                        )
                        DashboardMetricCard(
                            title: "Positive",
                            value: "\(currentBalance.positive)%",
                            detail: "soft and uplifting energy",
                            tint: EmotionKind.gratitude.color,
                            symbol: "sun.max.fill"
                        )
                        DashboardMetricCard(
                            title: "Negative",
                            value: "\(currentBalance.negative)%",
                            detail: "heavier emotional weight",
                            tint: EmotionKind.sadness.color,
                            symbol: "cloud.rain.fill"
                        )
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            CardSectionTitle(
                                title: "Filter the blend",
                                subtitle: "Focus on one emotional direction while you adjust the sliders."
                            )

                            HStack(spacing: 8) {
                                FilterButton(title: "All", isSelected: viewModel.emotionFilter == nil) {
                                    viewModel.emotionFilter = nil
                                }
                                FilterButton(title: "Positive", isSelected: viewModel.emotionFilter == .positive) {
                                    viewModel.emotionFilter = .positive
                                }
                                FilterButton(title: "Negative", isSelected: viewModel.emotionFilter == .negative) {
                                    viewModel.emotionFilter = .negative
                                }
                            }
                        }
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredEmotionKinds, id: \.self) { emotion in
                            let percentage = viewModel.currentEmotionDisplays.first(where: { $0.kind == emotion })?.percentage ?? 0
                            
                            EmotionSliderCard(
                                emotion: emotion,
                                value: Binding(
                                    get: { viewModel.rawEmotionValues[emotion, default: 0] },
                                    set: { viewModel.updateEmotion(emotion, to: $0) }
                                ),
                                percentage: percentage
                            )
                        }
                    }
                }
                .safeAreaPadding(.top, 8)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 132)
            }
        }
        .navigationTitle("My Moods")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            SaveButtonRow(
                isSaving: viewModel.isSaving,
                primaryTitle: "Save selected day",
                secondaryTitle: "Reset",
                primaryAction: {
                    viewModel.saveMood(context: modelContext)
                },
                secondaryAction: {
                    viewModel.resetMoodDraft()
                }
            )
            .padding(.horizontal, AppLayout.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 70)
            .background(
                LinearGradient(
                    colors: [Color.clear, AppTheme.background.opacity(0.92), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            viewModel.refresh(context: modelContext)
        }
    }
}

private struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AppTheme.rose : AppTheme.secondaryBackground.opacity(0.88))
            )
            .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
            .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MyMoodsView(viewModel: JournalViewModel())
            .modelContainer(PreviewData.makePreviewContainer())
    }
}
