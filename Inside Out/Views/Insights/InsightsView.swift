import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var securityController: AppSecurityController
    @ObservedObject var viewModel: JournalViewModel
    @AppStorage("insideout.userName") private var userName = ""
    @AppStorage("insideout.themeMode") private var themeMode: AppThemeMode = .system
    @AppStorage("insideout.reminder.enabled") private var reminderEnabled = false
    @AppStorage("insideout.reminder.hour") private var reminderHour = 20
    @AppStorage("insideout.reminder.minute") private var reminderMinute = 0
    @AppStorage(AppGroupConfig.hideThoughtsKey, store: UserDefaults(suiteName: AppGroupConfig.identifier)) private var hideThoughtsOnWidget = false
    @State private var reminderTime: Date = .now

    var weeklySummary: [EmotionSummary] {
        Array(viewModel.emotionSummary(for: 7).prefix(5))
    }

    var monthlySummary: [EmotionSummary] {
        Array(viewModel.emotionSummary(for: 30).prefix(5))
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        let weeklyRatio = viewModel.positiveNegativeRatio(for: 7)
        let monthlyRatio = viewModel.positiveNegativeRatio(for: 30)

        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    AppSectionHeader(
                        eyebrow: "Insights",
                        title: "Patterns worth noticing"
                    )

                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        DashboardMetricCard(
                            title: "Current streak",
                            value: "\(viewModel.currentStreak)",
                            detail: "consecutive recorded days",
                            tint: AppTheme.gold,
                            symbol: "flame.fill"
                        )
                        DashboardMetricCard(
                            title: "Journaled",
                            value: "\(viewModel.recordedDays(for: 30))/30",
                            detail: "days with saved activity this month",
                            tint: AppTheme.rose,
                            symbol: "calendar.badge.checkmark"
                        )
                        DashboardMetricCard(
                            title: "Weekly lead",
                            value: weeklySummary.first?.kind.name ?? "Open",
                            detail: "top emotion over the last 7 days",
                            tint: weeklySummary.first?.kind.color ?? AppTheme.rose,
                            symbol: "chart.bar.fill"
                        )
                        DashboardMetricCard(
                            title: "Monthly lead",
                            value: monthlySummary.first?.kind.name ?? "Open",
                            detail: "top emotion over the last 30 days",
                            tint: monthlySummary.first?.kind.color ?? AppTheme.gold,
                            symbol: "chart.line.uptrend.xyaxis"
                        )
                    }

                    if viewModel.totalRecordedDays == 0 {
                        PremiumCard {
                            EmptyStateView(
                                title: "Insights will grow here",
                                subtitle: "Once you save a few moods, thoughts, or memories, this screen will start showing patterns and balance over time."
                            )
                        }
                    } else {
                        PositiveNegativeRing(
                            title: "Last 7 days",
                            subtitle: "\(viewModel.recordedDays(for: 7)) recorded day\(viewModel.recordedDays(for: 7) == 1 ? "" : "s")",
                            positive: weeklyRatio.positive,
                            negative: weeklyRatio.negative
                        )
                        PositiveNegativeRing(
                            title: "Last 30 days",
                            subtitle: "\(viewModel.recordedDays(for: 30)) recorded day\(viewModel.recordedDays(for: 30) == 1 ? "" : "s")",
                            positive: monthlyRatio.positive,
                            negative: monthlyRatio.negative
                        )

                        if !weeklySummary.isEmpty {
                            EmotionBarChart(data: weeklySummary, title: "Weekly emotion mix")
                        }

                        if !monthlySummary.isEmpty {
                            EmotionBarChart(data: monthlySummary, title: "Monthly emotion mix")
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CardSectionTitle(
                                title: "Personalization",
                                subtitle: "Customize how Inside Out greets you each day."
                            )

                            PremiumTextField(
                                label: "Display Name",
                                text: $userName,
                                prompt: "Your name"
                            )
                            .textInputAutocapitalization(.words)
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CardSectionTitle(
                                title: "Appearance",
                                subtitle: "Choose how Inside Out looks on your device."
                            )

                            Picker("Appearance", selection: $themeMode) {
                                ForEach(AppThemeMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CardSectionTitle(
                                title: "Daily reminder",
                                subtitle: reminderEnabled
                                    ? "A gentle nudge arrives each day at \(reminderTime.formatted(date: .omitted, time: .shortened))."
                                    : "Turn on a daily nudge if you want a steadier check-in rhythm."
                            )

                            Toggle("Enable a gentle daily reminder", isOn: $reminderEnabled)
                                .tint(AppTheme.rose)

                            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .disabled(!reminderEnabled)
                                .opacity(reminderEnabled ? 1 : 0.55)
                        }
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 16) {
                            CardSectionTitle(
                                title: "Privacy & Security",
                                subtitle: "Protect the journal itself and control what the widget is allowed to reveal."
                            )

                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("App Lock")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text(
                                        securityController.biometricLockEnabled
                                            ? "Inside Out unlocks with \(securityController.unlockMethodLabel) or your device passcode."
                                            : "Require \(securityController.unlockMethodLabel) before opening your journal."
                                    )
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.mutedInk)
                                }

                                Spacer()

                                Button {
                                    Task {
                                        _ = await securityController.setBiometricLockEnabled(!securityController.biometricLockEnabled)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        if securityController.isAuthenticating {
                                            ProgressView()
                                                .controlSize(.small)
                                        }
                                        Text(securityController.biometricLockEnabled ? "Turn Off" : "Turn On")
                                            .font(.footnote.weight(.semibold))
                                    }
                                    .foregroundStyle(securityController.biometricLockEnabled ? AppTheme.ink : Color.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(securityController.biometricLockEnabled ? Color.white.opacity(0.88) : AppTheme.rose)
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .stroke(AppTheme.stroke.opacity(securityController.biometricLockEnabled ? 0.75 : 0), lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(securityController.isAuthenticating)
                            }

                            Toggle("Hide thought preview on widget", isOn: $hideThoughtsOnWidget)
                                .tint(AppTheme.rose)

                            Text(hideThoughtsOnWidget ? "Widgets will show “Unlock to see” instead of your saved thought preview." : "Widgets may display your latest saved thought preview on the Home Screen.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.mutedInk)

                            if let authenticationError = securityController.authenticationError {
                                Text(authenticationError)
                                    .font(.caption)
                                    .foregroundStyle(Color.red.opacity(0.8))
                            }
                        }
                    }
                }
                .safeAreaPadding(.top, 8)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh(context: modelContext)
            reminderTime = viewModel.reminderDate(hour: reminderHour, minute: reminderMinute)
        }
        .onChange(of: reminderEnabled) { _, enabled in
            Task {
                await viewModel.updateReminder(enabled: enabled, time: reminderTime)
            }
        }
        .onChange(of: reminderTime) { _, newTime in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
            reminderHour = components.hour ?? 20
            reminderMinute = components.minute ?? 0
            Task {
                await viewModel.updateReminder(enabled: reminderEnabled, time: newTime)
            }
        }
        .onChange(of: hideThoughtsOnWidget) { _, _ in
            viewModel.reloadWidgetSnapshot(context: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(viewModel: JournalViewModel())
            .modelContainer(PreviewData.makePreviewContainer())
            .environmentObject(AppSecurityController())
    }
}
