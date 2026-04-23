import SwiftUI

struct OnboardingView: View {
    @Binding var userName: String
    let onFinish: () -> Void
    @State private var index = 0

    private let pages: [(title: String, subtitle: String, emotion: EmotionKind)] = [
        ("Blend how you feel", "Shape your mood into a soft glowing orb that evolves as your emotions shift.", .love),
        ("Write one honest thought", "Capture the sentence, whisper, or truth that best holds your day.", .serenity),
        ("Make it personal", "Add your name for a greeting that feels like a private ritual, not just another tracker.", .gratitude)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 28) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { offset, page in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                Spacer(minLength: 40)
                                OrbView(
                                    emotions: [EmotionDisplay(kind: page.emotion, rawValue: 100, percentage: 100)],
                                    size: AppLayout.onboardingOrbSize
                                )
                                .padding(.bottom, 10)

                                HandwritingHeader(text: "Inside Out")

                                VStack(spacing: 12) {
                                    Text(page.title)
                                        .font(.system(size: 32, weight: .semibold, design: .serif))
                                        .foregroundStyle(AppTheme.ink)
                                        .multilineTextAlignment(.center)

                                    Text(page.subtitle)
                                        .font(.body)
                                        .foregroundStyle(AppTheme.mutedInk)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 12)

                                    if offset == pages.count - 1 {
                                        PremiumTextField(
                                            text: $userName,
                                            prompt: "Your name"
                                        )
                                        .textInputAutocapitalization(.words)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                    }
                                }
                                Spacer(minLength: 40)
                            }
                            .frame(minHeight: 500)
                        }
                        .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .ignoresSafeArea(.keyboard)

                Button {
                    if index < pages.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            index += 1
                        }
                    } else {
                        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            userName = "Friend"
                        }
                        onFinish()
                    }
                } label: {
                    Text(index == pages.count - 1 ? "Begin journaling" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppTheme.rose.gradient)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
    }
}

#Preview {
    OnboardingView(userName: .constant("Ege"), onFinish: {})
}
