import Foundation
import AuthenticationServices
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

    // MARK: - Sign In

    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let appleUserId = credential.user

        // Login to RevenueCat FIRST — must complete before subscription check
        do {
            _ = try await Purchases.shared.logIn(appleUserId)
            print("[RevenueCat] Logged in with Apple User ID: \(appleUserId)")
        } catch {
            print("[RevenueCat] logIn failed (non-fatal): \(error.localizedDescription)")
        }

        // Resolve name from Apple → Keychain → iCloud KV
        let credentialName = Self.extractFullName(from: credential.fullName)
        let resolvedName = UserPersistenceHelper.resolveName(
            fromAppleCredentialName: credentialName,
            userId: appleUserId
        )

        // Resolve email from Apple → iCloud KV
        let resolvedEmail = UserPersistenceHelper.resolveEmail(
            fromAppleCredentialEmail: credential.email,
            userId: appleUserId
        )

        // User exists locally — patch name/email if recovered
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

            if didChange {
                try await userRepository.updateUser(existingUser)
            }

            setRevenueCatAttributes(name: existingUser.name, email: existingUser.email)
            return existingUser
        }

        // Restore createdAt from Keychain/iCloud if user is reinstalling
        let restoredCreatedAt = UserPersistenceHelper.resolveCreatedAt(userId: appleUserId)
        let createdAt = restoredCreatedAt ?? Date()

        // New user
        let newUser = User(
            appleUserId: appleUserId,
            email: resolvedEmail,
            name: resolvedName,
            createdAt: createdAt
        )

        // Persist createdAt immediately
        UserPersistenceHelper.saveCreatedAt(createdAt, userId: appleUserId)

        // Restore streaks from iCloud KV if available
        if let streaks = UserPersistenceHelper.resolveStreaks(userId: appleUserId) {
            newUser.currentStreak = streaks.current
            newUser.longestStreak = streaks.longest
        }

        try await userRepository.createUser(newUser)
        setRevenueCatAttributes(name: newUser.name, email: newUser.email)
        return newUser
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> User? {
        return try await userRepository.getCurrentUser()
    }

    // MARK: - Sign Out

    func signOut() async throws {
        // 1. Delete all Screen Time rules — fresh start for next user
        try? await DIContainer.shared.screenTimeRulesUseCase.deleteAllRules()

        // 2. Delete local user
        try await userRepository.deleteCurrentUser()

        // 3. Reset RevenueCat
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            print("[Auth] RevenueCat logOut skipped: \(error.localizedDescription)")
        }

        // 4. Notify RootView
        await MainActor.run {
            NotificationCenter.default.post(name: .didSignOut, object: nil)
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        // 1. Cleanup Keychain + iCloud KV (includes email now)
        if let user = try await userRepository.getCurrentUser() {
            UserPersistenceHelper.deleteAll(userId: user.appleUserId)
        }

        // 2. Delete all Screen Time rules
        try? await DIContainer.shared.screenTimeRulesUseCase.deleteAllRules()

        // 3. Delete local user
        try await userRepository.deleteCurrentUser()

        // 4. Reset RevenueCat
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            print("[Auth] RevenueCat logOut skipped: \(error.localizedDescription)")
        }

        // 5. Notify RootView
        await MainActor.run {
            NotificationCenter.default.post(name: .didSignOut, object: nil)
        }
    }

    // MARK: - Helpers

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
        case .userNotFound:      return "User not found"
        case .cancelled:         return "Authentication was cancelled"
        }
    }
}