import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    func handleSignIn(result: Result<ASAuthorization, Error>) async -> User? {
        isLoading = true
        errorMessage = nil
        showError = false

        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            do {
                let user = try await DIContainer.shared.authService.signInWithApple(authorization: authorization)
                return user
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                return nil
            }

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
                showError = true
            }
            return nil
        }
    }

    func getCurrentUser() async -> User? {
        do {
            return try await DIContainer.shared.authService.getCurrentUser()
        } catch {
            return nil
        }
    }
}
