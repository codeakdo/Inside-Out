import SwiftUI
import Charts

enum AppLayout {
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 22
    static let cardSpacing: CGFloat = 14
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 26
    static let controlRadius: CGFloat = 18
    static let heroOrbSize: CGFloat = 248
    static let showcaseOrbSize: CGFloat = 224
    static let detailOrbSize: CGFloat = 208
    static let onboardingOrbSize: CGFloat = 224
    static let shareOrbSize: CGFloat = 176
    static let selectedMiniOrbSize: CGFloat = 48
    static let miniOrbSize: CGFloat = 38
    static let metricCardHeight: CGFloat = 116
    static let ringSize: CGFloat = 168
    static let chartHeight: CGFloat = 210
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.background, AppTheme.secondaryBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct PremiumCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: AppTheme.ink.opacity(0.08), radius: 20, x: 0, y: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .stroke(AppTheme.stroke.opacity(0.75), lineWidth: 1)
            }
    }
}

struct AppSectionHeader: View {
    let eyebrow: String
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .tracking(1.4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            trailing?.fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(AppTheme.rose)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(AppTheme.mutedInk)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.rose)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let detail: String
    var tint: Color = AppTheme.rose
    var symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .tracking(1)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(AppTheme.mutedInk)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: AppLayout.metricCardHeight, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.8), lineWidth: 1)
        }
    }
}

struct CardSectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HandwritingHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Snell Roundhand", size: 34))
            .foregroundStyle(AppTheme.ink)
    }
}

struct OrbView: View {
    let emotions: [EmotionDisplay]
    var size: CGFloat = 260
    var showGlow: Bool = true
    var isSubtle: Bool = false
    var animationTick: Double = 0
    var isStatic: Bool = false
    @State private var animate = false

    private var amplitude: CGFloat {
        isSubtle ? 3 : 22
    }

    private var duration: Double {
        isSubtle ? 14 : 9
    }

    var body: some View {
        VStack(alignment: .center) {
            SharedOrbCore(presentation: presentation, size: size, showGlow: showGlow)
                .frame(width: size, height: size)
                .scaleEffect(isStatic ? 1.0 : (animate ? 1.03 : 0.97))
                .offset(x: isStatic ? 0 : (animate ? amplitude : -amplitude))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: size + (showGlow ? size * 0.2 : 0))
        .animation(isStatic ? nil : .easeInOut(duration: duration).repeatForever(autoreverses: true), value: animate)
        .animation(.spring(response: 0.9, dampingFraction: 0.92), value: emotions)
        .animation(.spring(response: 0.8, dampingFraction: 0.88), value: animationTick)
        .onAppear {
            if !isStatic {
                animate = true
            }
        }
    }

    private var normalizedEmotions: [EmotionDisplay] {
        emotions.isEmpty ? [EmotionDisplay(kind: .serenity, rawValue: 100, percentage: 100)] : emotions
    }

    private var presentation: SharedMoodPresentation {
        let snapshot = SharedMoodSnapshot(
            date: .now,
            dominantEmotion: normalizedEmotions.first?.name ?? "Serenity",
            thoughtPreview: nil,
            emotions: normalizedEmotions.map {
                SharedMoodEmotion(
                    kind: $0.kind.rawValue,
                    name: $0.name,
                    colorHex: $0.kind.hexString,
                    category: $0.category.rawValue,
                    percentage: $0.percentage
                )
            },
            hideThoughts: false
        )
        return SharedMoodRenderer.presentation(for: snapshot)
    }
}

struct SegmentedPicker<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    let items: [T]
    @Binding var selection: T
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        selection = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == item ? Color.white : AppTheme.mutedInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selection == item {
                                Capsule(style: .continuous)
                                    .fill(AppTheme.rose)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            } else {
                                Capsule(style: .continuous)
                                    .fill(AppTheme.secondaryBackground.opacity(0.42))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.secondaryBackground.opacity(0.85))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.65), lineWidth: 1)
        }
    }
}

struct WeeklyOrbRow: View {
    let days: [WeeklyOrbDay]
    let selectedDate: Date
    let onSelect: (Date) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(days, id: \.date) { day in
                    let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)

                    Button {
                        onSelect(day.date)
                    } label: {
                        VStack(spacing: 8) {
                            Text(day.date.dayTitle.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(isSelected ? AppTheme.ink : AppTheme.mutedInk)
                                .tracking(0.8)

                            OrbView(
                                emotions: (day.entry?.emotions ?? []).map {
                                    EmotionDisplay(kind: $0.kind, rawValue: $0.rawValue, percentage: $0.percentage)
                                },
                                size: isSelected ? AppLayout.selectedMiniOrbSize : AppLayout.miniOrbSize,
                                showGlow: false,
                                isStatic: true
                            )

                            Text(day.date.dayNumberTitle)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(isSelected ? AppTheme.ink : AppTheme.mutedInk)
                        }
                        .frame(width: 64)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.94) : Color.white.opacity(0.42))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? AppTheme.stroke.opacity(0.9) : Color.clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

struct EmotionRowView: View {
    let emotion: EmotionDisplay

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(emotion.color)
                .frame(width: 14, height: 14)
                .shadow(color: emotion.color.opacity(0.5), radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(emotion.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(emotion.category.title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(emotion.formattedPercentage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .monospacedDigit()

                Capsule(style: .continuous)
                    .fill(AppTheme.secondaryBackground.opacity(0.9))
                    .frame(width: 76, height: 6)
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(emotion.color)
                            .frame(width: max(12, 76 * emotion.normalizedShare), height: 6)
                    }
            }
        }
    }
}

struct EmotionSliderCard: View {
    let emotion: EmotionKind
    @Binding var value: Double
    var percentage: Double = 0

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(emotion.name, systemImage: "sparkle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text("Intensity: \(Int(value.rounded()))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.mutedInk)
                        .monospacedDigit()
                }

                Slider(value: $value, in: 0...100, step: 1)
                    .tint(emotion.color)
                    .sensoryFeedback(.selection, trigger: value)
                    .padding(.vertical, 2)

                HStack {
                    Text(emotion.description)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if percentage > 0.001 {
                        Text("Contribution: \(Int(percentage.rounded()))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.rose)
                    }
                }
            }
        }
    }
}

struct ThoughtComposerCard: View {
    @Binding var text: String
    let suggestions: [String]
    let characterCount: Int
    let onTapSuggestion: (String) -> Void

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Capture a thought")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text("\(characterCount)/280")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(characterCount > 260 ? Color.red.opacity(0.7) : AppTheme.mutedInk)
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 148)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                                .fill(AppTheme.secondaryBackground.opacity(0.85))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                                .stroke(AppTheme.stroke.opacity(0.7), lineWidth: 1)
                        }

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("What felt loud, tender, or true today?")
                            .font(.body)
                            .foregroundStyle(AppTheme.mutedInk.opacity(0.72))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested tags")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.mutedInk)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    onTapSuggestion(suggestion)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AppTheme.secondaryBackground.opacity(0.85)))
                                .foregroundStyle(AppTheme.ink)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Text("Keep it short and honest.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

struct PremiumTextField: View {
    var label: String = ""
    @Binding var text: String
    var prompt: String = ""
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
            }

            HStack(spacing: 10) {
                TextField(prompt, text: $text, axis: axis)
                    .font(.body)
                    .foregroundStyle(AppTheme.ink)

                if !text.isEmpty {
                    Button {
                        text = ""
                        AppTheme.triggerHaptic(.light)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.mutedInk.opacity(0.6))
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                    .fill(AppTheme.secondaryBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                    .stroke(AppTheme.stroke.opacity(0.8), lineWidth: 1)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
    }
}

struct PremiumSearchField: View {
    @Binding var text: String
    var prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.mutedInk)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(AppTheme.ink)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.mutedInk.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                .fill(AppTheme.secondaryBackground.opacity(0.85))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppLayout.controlRadius, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.75), lineWidth: 1)
        }
    }
}

struct ThoughtCardView: View {
    let thought: ThoughtEntry
    let onPin: () -> Void
    let onEdit: () -> Void

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(thought.isPinned ? "Pinned Thought" : "Thought")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.mutedInk)
                        .tracking(1.1)
                    Spacer()
                    Button(action: onPin) {
                        Image(systemName: thought.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(thought.isPinned ? AppTheme.rose : AppTheme.mutedInk)
                    }
                    .buttonStyle(.plain)
                }

                Text(thought.text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink.opacity(0.9))
                    .lineSpacing(2)

                if !thought.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(thought.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.mutedInk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(AppTheme.secondaryBackground.opacity(0.9)))
                            }
                        }
                    }
                }

                HStack {
                    Text(thought.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedInk)
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.rose)
                }
            }
        }
    }
}

struct MemoryCardView: View {
    let memory: MemoryRecord

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(memory.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    if let tag = memory.tag {
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule(style: .continuous).fill(AppTheme.secondaryBackground))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }

                Text(memory.bodyText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink.opacity(0.85))

                Text(memory.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

struct SaveButtonRow: View {
    let isSaving: Bool
    let primaryTitle: String
    let secondaryTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let secondaryTitle, let secondaryAction {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.secondaryBackground.opacity(0.85))
                    )
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(AppTheme.stroke.opacity(0.6), lineWidth: 1)
                    }
                    .buttonStyle(.plain)
            }

            Button(action: {
                AppTheme.triggerHaptic(.medium)
                primaryAction()
            }) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(primaryTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .foregroundStyle(.white)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.rose.gradient)
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: AppTheme.ink.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.75), lineWidth: 1)
        }
    }
}

struct InsightSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

struct EmotionBarChart: View {
    let data: [EmotionSummary]
    let title: String

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)

                Chart(data) { item in
                    BarMark(
                        x: .value("Emotion", item.kind.name),
                        y: .value("Share", item.total)
                    )
                    .foregroundStyle(item.kind.color.gradient)
                    .cornerRadius(8)
                }
                .frame(height: AppLayout.chartHeight)
                .chartYAxis(.hidden)
            }
        }
    }
}

struct PositiveNegativeRing: View {
    let title: String
    let subtitle: String
    let positive: Double
    let negative: Double

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                CardSectionTitle(title: title, subtitle: subtitle)

                ZStack {
                    Circle()
                        .stroke(AppTheme.secondaryBackground, lineWidth: 18)

                    Circle()
                        .trim(from: 0, to: positive)
                        .stroke(EmotionKind.gratitude.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: positive, to: min(positive + negative, 1))
                        .stroke(EmotionKind.sadness.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(Int((positive * 100).rounded()))%")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text("Positive energy")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
                .frame(height: AppLayout.ringSize)

                HStack(spacing: 12) {
                    Label("\(Int((positive * 100).rounded()))% positive", systemImage: "sun.max.fill")
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Label("\(Int((negative * 100).rounded()))% negative", systemImage: "cloud.rain.fill")
                        .foregroundStyle(AppTheme.mutedInk)
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }
}

struct ShareableMoodCardView: View {
    let date: Date
    let emotions: [EmotionDisplay]
    let dominantEmotion: String
    let thoughtPreview: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppTheme.secondaryBackground.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 20) {
                Text(date.monthDayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .tracking(1.4)

                HandwritingHeader(text: "Inside Out")

                OrbView(emotions: emotions, size: AppLayout.shareOrbSize)

                Text(dominantEmotion)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.ink)

                Text(thoughtPreview ?? "A soft emotional snapshot.")
                    .font(.body)
                    .foregroundStyle(AppTheme.ink.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .frame(maxWidth: 280)
            }
            .padding(28)
        }
        .frame(width: 360, height: 520)
        .overlay {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.8), lineWidth: 1)
        }
    }
}
