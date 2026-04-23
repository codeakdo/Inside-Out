import SwiftUI
import SwiftData
import LocalAuthentication

struct AppContainerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("insideout.hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("insideout.userName") private var userName = ""
    @AppStorage("insideout.themeMode") private var themeMode: AppThemeMode = .system
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var securityController = AppSecurityController()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#1A1A1A")
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(hex: "#A1A1A6")
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hex: "#A1A1A6")]
        itemAppearance.selected.iconColor = UIColor(hex: "#FF7A8A")
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "#FF7A8A")]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var shouldPresentLock: Bool {
        hasSeenOnboarding && securityController.requiresUnlock
    }

    var body: some View {
        ZStack {
            Group {
                if hasSeenOnboarding {
                    MainTabContainerView(viewModel: viewModel, userName: userName)
                } else {
                    OnboardingView(userName: $userName) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
                            hasSeenOnboarding = true
                        }
                    }
                }
            }
            .environmentObject(securityController)
            .overlay {
                if shouldPresentLock {
                    AppLockOverlayView(securityController: securityController)
                        .transition(.opacity)
                }
            }
            .allowsHitTesting(!shouldPresentLock)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.rose)
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .tint(AppTheme.rose)
        .task {
            guard hasSeenOnboarding else { return }
            await securityController.unlockIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                guard hasSeenOnboarding else { return }
                Task {
                    await securityController.unlockIfNeeded()
                }
            case .background:
                securityController.lockIfNeeded()
            default:
                break
            }
        }
    }
}

struct MainTabContainerView: View {
    @ObservedObject var viewModel: JournalViewModel
    let userName: String
    @Namespace private var tabAnimation

    var body: some View {
        ZStack {
            switch viewModel.selectedRootTab {
            case .home:
                NavigationStack { HomeDashboardView(viewModel: viewModel, userName: userName) }
            case .moods:
                NavigationStack { MyMoodsView(viewModel: viewModel) }
            case .thoughts:
                NavigationStack { ThoughtsView(viewModel: viewModel) }
            case .memories:
                NavigationStack { MemoriesView(viewModel: viewModel) }
            case .history:
                NavigationStack { HistoryView(viewModel: viewModel) }
            case .insights:
                NavigationStack { InsightsView(viewModel: viewModel) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PremiumTabBar(selection: $viewModel.selectedRootTab, namespace: tabAnimation)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
    }
}

private struct PremiumTabBar: View {
    @Binding var selection: RootTab
    let namespace: Namespace.ID

    private let items: [(RootTab, String, String)] = [
        (.home, String(localized: "Home"), "sparkles"),
        (.moods, String(localized: "Moods"), "circle.hexagongrid.fill"),
        (.thoughts, String(localized: "Thoughts"), "pencil.and.scribble"),
        (.memories, String(localized: "Memories"), "heart.text.square.fill"),
        (.history, String(localized: "History"), "calendar"),
        (.insights, String(localized: "Insights"), "chart.xyaxis.line")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.0) { item in
                    Button {
                        if selection != item.0 {
                            AppTheme.triggerHaptic(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                selection = item.0
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.2)
                                .font(.subheadline.weight(.semibold))
                            if selection == item.0 {
                                Text(item.1)
                                    .font(.subheadline.weight(.semibold))
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .foregroundStyle(selection == item.0 ? Color.white : AppTheme.mutedInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background {
                            if selection == item.0 {
                                Capsule(style: .continuous)
                                    .fill(AppTheme.rose.gradient)
                                    .matchedGeometryEffect(id: "tab-pill", in: namespace)
                            } else {
                                Capsule(style: .continuous)
                                    .fill(Color.clear)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(7)
        }
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.secondaryBackground.opacity(0.92))
                .shadow(color: AppTheme.ink.opacity(0.06), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview {
    AppContainerView()
        .modelContainer(PreviewData.makePreviewContainer())
}

@MainActor
final class AppSecurityController: ObservableObject {
    private static let biometricLockKey = "insideout.security.biometricLockEnabled"
    private let defaults = UserDefaults.standard

    @Published private(set) var biometricLockEnabled: Bool
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isAuthenticating = false
    @Published private(set) var unlockMethodLabel = "Face ID"
    @Published private(set) var isAuthenticationAvailable = false
    @Published var authenticationError: String?

    init() {
        let enabled = defaults.bool(forKey: Self.biometricLockKey)
        biometricLockEnabled = enabled
        isUnlocked = !enabled
        refreshAuthenticationAvailability()
    }

    var requiresUnlock: Bool {
        biometricLockEnabled && !isUnlocked
    }

    func setBiometricLockEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            refreshAuthenticationAvailability()
            guard isAuthenticationAvailable else {
                authenticationError = "Face ID, Touch ID, or passcode authentication is not available on this device."
                return false
            }

            let didAuthenticate = await authenticate(reason: "Turn on app lock for Inside Out.")
            guard didAuthenticate else { return false }

            biometricLockEnabled = true
            defaults.set(true, forKey: Self.biometricLockKey)
            isUnlocked = true
            return true
        } else {
            biometricLockEnabled = false
            defaults.set(false, forKey: Self.biometricLockKey)
            isUnlocked = true
            authenticationError = nil
            return true
        }
    }

    func unlockIfNeeded() async {
        guard requiresUnlock, !isAuthenticating else { return }
        _ = await authenticate(reason: "Unlock Inside Out to view your journal.")
    }

    func lockIfNeeded() {
        guard biometricLockEnabled else { return }
        isUnlocked = false
        authenticationError = nil
    }

    private func authenticate(reason: String) async -> Bool {
        let biometricsContext = LAContext()
        biometricsContext.localizedCancelTitle = String(localized: "Vazgeç")
        biometricsContext.localizedFallbackTitle = String(localized: "Şifre Kullan")

        var authError: NSError?
        let canDoBiometric = biometricsContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
        
        isAuthenticating = true
        defer { isAuthenticating = false }

        // 1. Try Biometrics first if available
        if canDoBiometric {
            do {
                let success = try await biometricsContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                if success {
                    isUnlocked = true
                    authenticationError = nil
                    return true
                }
            } catch {
                // If user cancels, we exit. If it's a failure (like too many attempts), we fall through to Passcode.
                if (error as NSError).code == LAError.userCancel.rawValue {
                    return false
                }
            }
        }

        // 2. Fallback to deviceOwnerAuthentication (Passcode)
        // CRITICAL: We MUST create a new context for the fallback evaluation to avoid crashes.
        let fallbackContext = LAContext()
        fallbackContext.localizedCancelTitle = String(localized: "Vazgeç")
        
        do {
            let success = try await fallbackContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                isUnlocked = true
                authenticationError = nil
            }
            return success
        } catch {
            authenticationError = (error as NSError).localizedDescription
            return false
        }
    }

    private func refreshAuthenticationAvailability() {
        let context = LAContext()
        var error: NSError?
        let canAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        updateAuthenticationMetadata(using: context, isAvailable: canAuthenticate)
    }

    private func updateAuthenticationMetadata(using context: LAContext, isAvailable: Bool) {
        isAuthenticationAvailable = isAvailable
        switch context.biometryType {
        case .faceID:
            unlockMethodLabel = "Face ID"
        case .touchID:
            unlockMethodLabel = "Touch ID"
        default:
            unlockMethodLabel = "Passcode"
        }
    }
}

private struct AppLockOverlayView: View {
    @ObservedObject var securityController: AppSecurityController

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            PremiumCard {
                VStack(spacing: 18) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppTheme.rose)

                    VStack(spacing: 8) {
                        Text(String(localized: "Journal Locked"))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)

                        Text(String(localized: "Use \(securityController.unlockMethodLabel) or your device passcode to open Inside Out."))
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                            .multilineTextAlignment(.center)
                    }

                    if let authenticationError = securityController.authenticationError {
                        Text(authenticationError)
                            .font(.caption)
                            .foregroundStyle(Color.red.opacity(0.78))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await securityController.unlockIfNeeded()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if securityController.isAuthenticating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(securityController.isAuthenticating ? String(localized: "Unlocking...") : String(localized: "Unlock"))
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.rose.gradient)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(securityController.isAuthenticating)

                    Button {
                        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                    } label: {
                        Text(String(localized: "Vazgeç"))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: 340)
            }
            .padding(.horizontal, 24)
        }
    }
}
