import AuthenticationServices
import Foundation
import RevenueCat

protocol AuthService {
    func signInWithApple(authorization: ASAuthorization) async throws -> User
    func getCurrentUser() async throws -> User?
    func signOut() async throws
    func deleteAccount() async throws
}

final class AuthServiceImpl: AuthService {
    let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let appleUserId = credential.user

        do {
            _ = try await Purchases.shared.logIn(appleUserId)
            print("[RevenueCat] Logged in with Apple User ID: \(appleUserId)")
        } catch {
            print("[RevenueCat] logIn failed (non-fatal): \(error.localizedDescription)")
        }

        let credentialName = Self.extractFullName(from: credential.fullName)
        let resolvedName = UserPersistenceHelper.resolveName(
            fromAppleCredentialName: credentialName,
            userId: appleUserId
        )

        let resolvedEmail = UserPersistenceHelper.resolveEmail(
            fromAppleCredentialEmail: credential.email,
            userId: appleUserId
        )

        if var existingUser = try await userRepository.getUser(byAppleUserId: appleUserId) {
            var didChange = false

            if existingUser.name == nil, let name = resolvedName {
                existingUser.name = name
                didChange = true
            }
            if existingUser.email == nil, let email = resolvedEmail {
                existingUser.email = email
                didChange = true
            }

            // Restore streaks from iCloud KV (primary source)
            if let streaks = UserPersistenceHelper.resolveStreaks(userId: appleUserId) {
                print("🔄 Restoring streaks from iCloud: current=\(streaks.current), longest=\(streaks.longest)")
                existingUser.currentStreak = streaks.current
                existingUser.longestStreak = streaks.longest
                didChange = true
            }

            if didChange {
                try await userRepository.updateUser(existingUser)
            }

            setRevenueCatAttributes(name: existingUser.name, email: existingUser.email)
            return existingUser
        }

        let restoredCreatedAt = UserPersistenceHelper.resolveCreatedAt(userId: appleUserId)
        let createdAt = restoredCreatedAt ?? Date()

        let newUser = User(
            appleUserId: appleUserId,
            email: resolvedEmail,
            name: resolvedName,
            createdAt: createdAt
        )

        UserPersistenceHelper.saveCreatedAt(createdAt, userId: appleUserId)

        if let streaks = UserPersistenceHelper.resolveStreaks(userId: appleUserId) {
            newUser.currentStreak = streaks.current
            newUser.longestStreak = streaks.longest
        }

        try await userRepository.createUser(newUser)
        setRevenueCatAttributes(name: newUser.name, email: newUser.email)
        return newUser
    }

    func getCurrentUser() async throws -> User? {
        return try await userRepository.getCurrentUser()
    }

    func signOut() async throws {
        try? await DIContainer.shared.screenTimeRulesService.deleteAllRules()
        try await userRepository.deleteCurrentUser()

        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            print("[Auth] RevenueCat logOut skipped: \(error.localizedDescription)")
        }

        await MainActor.run {
            NotificationCenter.default.post(name: .didSignOut, object: nil)
        }
    }

    func deleteAccount() async throws {
        if let user = try await userRepository.getCurrentUser() {
            UserPersistenceHelper.deleteAll(userId: user.appleUserId)
        }

        try? await DIContainer.shared.screenTimeRulesService.deleteAllRules()

        try await userRepository.deleteCurrentUser()

        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            print("[Auth] RevenueCat logOut skipped: \(error.localizedDescription)")
        }

        await MainActor.run {
            NotificationCenter.default.post(name: .didSignOut, object: nil)
        }
    }

    private func setRevenueCatAttributes(name: String?, email: String?) {
        if let name { Purchases.shared.attribution.setDisplayName(name) }
        if let email { Purchases.shared.attribution.setEmail(email) }
    }

    private static func extractFullName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let parts = [components.givenName, components.familyName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case userNotFound
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid authentication credential"
        case .userNotFound: return "User not found"
        case .cancelled: return "Authentication was cancelled"
        }
    }
}
