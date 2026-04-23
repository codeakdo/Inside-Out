import SwiftUI
import SwiftData

struct MemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: JournalViewModel

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var latestMemoryLabel: String {
        guard let latestMemory = viewModel.selectedDayMemories.first else { return "nothing saved yet" }
        return "last saved at \(latestMemory.createdAt.formatted(.dateTime.hour().minute()))"
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    AppSectionHeader(
                        eyebrow: "Memory notes",
                        title: viewModel.selectedDate.shortMonthDay,
                        trailing: AnyView(
                            Button {
                                viewModel.showingMemoryComposer = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .padding(10)
                                    .background(Circle().fill(Color.white.opacity(0.94)))
                            }
                            .buttonStyle(.plain)
                        )
                    )

                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        DashboardMetricCard(
                            title: "Saved today",
                            value: "\(viewModel.selectedDayMemories.count)",
                            detail: latestMemoryLabel,
                            tint: AppTheme.rose,
                            symbol: "bookmark.fill"
                        )
                        DashboardMetricCard(
                            title: "Mood link",
                            value: viewModel.dominantEmotion?.name ?? "Open",
                            detail: viewModel.dominantEmotion?.kind.description ?? "Save a mood blend to pair with your memories.",
                            tint: viewModel.dominantEmotion?.color ?? AppTheme.gold,
                            symbol: "sparkles"
                        )
                    }

                    if viewModel.selectedDayMemories.isEmpty {
                        PremiumCard {
                            EmptyStateView(
                                title: "No saved moments",
                                subtitle: "Capture one memory from the day so it stays attached to your emotional blend.",
                                actionTitle: "Create a memory",
                                action: {
                                    viewModel.showingMemoryComposer = true
                                }
                            )
                        }
                    } else {
                        LazyVStack(spacing: AppLayout.cardSpacing) {
                            ForEach(viewModel.selectedDayMemories) { memory in
                                MemoryCardView(memory: memory)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            viewModel.deleteMemory(memory, context: modelContext)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .safeAreaPadding(.top, 8)
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationTitle("Memories")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingMemoryComposer) {
            NavigationStack {
                ZStack {
                    AppBackground()
                    ScrollView {
                        VStack(spacing: AppLayout.sectionSpacing) {
                            PremiumCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    CardSectionTitle(
                                        title: "Capture a memory",
                                        subtitle: "A short title and one vivid detail are enough to make the moment feel real later."
                                    )

                                    PremiumTextField(
                                        label: "Title",
                                        text: $viewModel.memoryTitle,
                                        prompt: "Golden hour tea"
                                    )
                                    .textInputAutocapitalization(.words)
                                    .font(.headline)

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("What happened")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(AppTheme.mutedInk)
                                            Spacer()
                                            Text("\(viewModel.memoryBody.count)/220")
                                                .font(.footnote.monospacedDigit())
                                                .foregroundStyle(viewModel.memoryBody.count > 200 ? Color.red.opacity(0.7) : AppTheme.mutedInk)
                                        }

                                        ZStack(alignment: .topLeading) {
                                            TextEditor(text: $viewModel.memoryBody)
                                                .frame(minHeight: 168)
                                                .padding(12)
                                                .scrollContentBackground(.hidden)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                                                        .fill(AppTheme.secondaryBackground.opacity(0.6))
                                                )
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                                                        .stroke(AppTheme.stroke.opacity(0.8), lineWidth: 1)
                                                }

                                            if viewModel.memoryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                Text("A smell, a sentence, a tiny detail you want future-you to remember.")
                                                    .font(.body)
                                                    .foregroundStyle(AppTheme.mutedInk.opacity(0.72))
                                                    .padding(.horizontal, 18)
                                                    .padding(.vertical, 22)
                                                    .allowsHitTesting(false)
                                            }
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 10) {
                                        PremiumTextField(
                                            label: "Tag it",
                                            text: $viewModel.memoryTag,
                                            prompt: "#ritual"
                                        )
                                        .textInputAutocapitalization(.never)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(Array(viewModel.hashtagSuggestions.prefix(4)), id: \.self) { suggestion in
                                                    Button(suggestion) {
                                                        viewModel.applyMemoryTag(suggestion)
                                                    }
                                                    .font(.caption.weight(.semibold))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Capsule().fill(Color.white.opacity(0.9)))
                                                    .foregroundStyle(AppTheme.ink)
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            PremiumCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    CardSectionTitle(
                                        title: "Why it matters",
                                        subtitle: "These memories show up beside your mood blend later, so little concrete details tend to feel strongest."
                                    )
                                }
                            }

                            SaveButtonRow(
                                isSaving: viewModel.isSaving,
                                primaryTitle: "Save memory",
                                secondaryTitle: "Dismiss",
                                primaryAction: {
                                    viewModel.addMemory(context: modelContext)
                                },
                                secondaryAction: {
                                    viewModel.showingMemoryComposer = false
                                }
                            )
                        }
                        .padding(AppLayout.screenPadding)
                    }
                }
                .navigationTitle("New Memory")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            viewModel.refresh(context: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        MemoriesView(viewModel: JournalViewModel())
            .modelContainer(PreviewData.makePreviewContainer())
    }
}
