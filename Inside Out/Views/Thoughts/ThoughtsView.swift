import SwiftUI
import SwiftData

struct ThoughtsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: JournalViewModel

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                    AppSectionHeader(
                        eyebrow: viewModel.thoughtComposer.isEditing ? "Edit thought" : "Daily thoughts",
                        title: "A quiet note for \(viewModel.selectedDate.shortMonthDay)"
                    )

                    ThoughtComposerCard(
                        text: $viewModel.thoughtComposer.text,
                        suggestions: viewModel.hashtagSuggestions,
                        characterCount: viewModel.thoughtCharacterCount,
                        onTapSuggestion: viewModel.applySuggestion
                    )

                    PremiumCard {
                        PremiumTextField(
                            label: "Tags",
                            text: $viewModel.thoughtComposer.tags,
                            prompt: "#gratitude #reset"
                        )
                        .textInputAutocapitalization(.never)
                    }

                    if viewModel.selectedDayThoughts.isEmpty {
                        PremiumCard {
                            EmptyStateView(title: "No thoughts saved", subtitle: "Add a few honest lines for this day and pin the one you want to keep closest.")
                        }
                    } else {
                        LazyVStack(spacing: AppLayout.cardSpacing) {
                            ForEach(viewModel.selectedDayThoughts) { thought in
                                ThoughtCardView(
                                    thought: thought,
                                    onPin: {
                                        viewModel.togglePinned(thought, context: modelContext)
                                    },
                                    onEdit: {
                                        viewModel.beginEditingThought(thought)
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteThought(thought, context: modelContext)
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
                .padding(.bottom, 132)
            }
        }
        .navigationTitle("Thoughts")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            SaveButtonRow(
                isSaving: viewModel.isSaving,
                primaryTitle: viewModel.thoughtComposer.isEditing ? "Update thought" : "Add thought",
                secondaryTitle: viewModel.thoughtComposer.isEditing ? "Cancel" : nil,
                primaryAction: {
                    viewModel.saveThought(context: modelContext)
                },
                secondaryAction: viewModel.thoughtComposer.isEditing ? {
                    viewModel.cancelEditingThought()
                } : nil
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

#Preview {
    NavigationStack {
        ThoughtsView(viewModel: JournalViewModel())
            .modelContainer(PreviewData.makePreviewContainer())
    }
}
