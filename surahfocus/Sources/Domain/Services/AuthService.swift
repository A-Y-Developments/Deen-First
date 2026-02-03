import Foundation
import AuthenticationServices

protocol AuthService {
    func signInWithApple(
        authorization: ASAuthorization
    ) async throws -> User
    func getCurrentUser() async throws -> User?
    func signOut() async throws
}

final class AuthServiceImpl: AuthService {
    let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func signInWithApple(
        authorization: ASAuthorization
    ) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let appleUserId = credential.user

        // Check if user already exists
        if let existingUser = try await userRepository.getUser(byAppleUserId: appleUserId) {
            return existingUser
        }

        // Create new user
        let newUser = User(
            appleUserId: appleUserId,
            email: credential.email,
            name: credential.fullName?.givenName
        )

        try await userRepository.createUser(newUser)
        return newUser
    }

    func getCurrentUser() async throws -> User? {
        return try await userRepository.getCurrentUser()
    }

    func signOut() async throws {
        try await userRepository.deleteCurrentUser()
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case userNotFound
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credential"
        case .userNotFound:
            return "User not found"
        case .cancelled:
            return "Authentication was cancelled"
        }
    }
}
