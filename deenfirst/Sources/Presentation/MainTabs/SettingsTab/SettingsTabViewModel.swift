import SwiftUI
import RevenueCat

@MainActor
final class SettingsTabViewModel: ObservableObject {
    @Published var user: User?
    @Published var isPremium: Bool = false   // from RevenueCat, not User model
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false

    private let userRepository: UserRepository
    private let authService: AuthService
    private let subscriptionService: SubscriptionService

    init(
        userRepository: UserRepository,
        authService: AuthService,
        subscriptionService: SubscriptionService
    ) {
        self.userRepository = userRepository
        self.authService = authService
        self.subscriptionService = subscriptionService
    }

    convenience init() {
        self.init(
            userRepository: DIContainer.shared.userRepository,
            authService: DIContainer.shared.authService,
            subscriptionService: DIContainer.shared.subscriptionService
        )
    }

    // MARK: - Actions

    func loadUserData() async {
        isLoading = true
        errorMessage = nil

        async let userResult = userRepository.getCurrentUser()
        async let premiumResult = subscriptionService.checkSubscriptionStatus()

        do {
            user = try await userResult
            isPremium = (try? await premiumResult) ?? false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Display Helpers

    var displayName: String {
        guard let user else { return "User" }
        if let name = user.name, !name.isEmpty { return name }
        if let email = user.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "User"
        }
        return "User"
    }

    var displayInitial: String {
        String(displayName.prefix(1)).uppercased()
    }

    var streakText: String {
        "\(user?.currentStreak ?? 0) day streak"
    }

    var subscriptionStatusText: String {
        isLoading ? "Loading..." : (isPremium ? "Premium" : "Free")
    }

    var isSubscribed: Bool { isPremium }
    var email: String? { user?.email }
    var currentStreak: Int { user?.currentStreak ?? 0 }
}