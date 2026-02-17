import SwiftUI
import RevenueCat

@MainActor
final class SettingsTabViewModel: ObservableObject {
    @Published var user: User?
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

    func loadUserData() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await userRepository.getCurrentUser()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        guard let user = user else {
            errorMessage = "User not found"
            return
        }

        do {
            try await userRepository.deleteCurrentUser()
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var displayName: String {
        guard let user = user else { return "User" }
        if let name = user.name, !name.isEmpty {
            return name
        }
        return "User"
    }

    var displayInitial: String {
        let name = displayName
        return name.isEmpty ? "U" : String(name.prefix(1)).uppercased()
    }

    var streakText: String {
        guard let user = user else { return "0 day streak" }
        return "\(user.currentStreak) day streak"
    }

    var subscriptionStatusText: String {
        guard let user = user else { return "Loading..." }
        return user.isPremium ? "Premium" : "Free"
    }

    var isSubscribed: Bool {
        user?.isPremium ?? false
    }

    var email: String? {
        user?.email
    }

    var currentStreak: Int {
        user?.currentStreak ?? 0
    }
}
