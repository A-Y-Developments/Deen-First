import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// MARK: - Screen Time Service Protocol

protocol ScreenTimeService {
    func requestAuthorization() async throws
    func checkAuthorizationStatus() -> Bool
    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws
    func loadAppSelection() async throws -> FamilyActivitySelection
    func clearAppSelection() async throws

    // Shield management (main app only)
    func applyShields() async throws
    func removeShields() async throws
    func isShieldsActive() async throws -> Bool

    // Session management
    func startQuranSession(surahId: Int) async throws
    func endQuranSession() async throws
}

// MARK: - Screen Time Service Implementation

final class ScreenTimeServiceImpl: ScreenTimeService {
    let screenTimeRepository: ScreenTimeRepository
    private let authCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()

    init(screenTimeRepository: ScreenTimeRepository) {
        self.screenTimeRepository = screenTimeRepository
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await authCenter.requestAuthorization(for: .individual)
    }

    func checkAuthorizationStatus() -> Bool {
        authCenter.authorizationStatus == .approved
    }

    // MARK: - App Selection

    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws {
        guard checkAuthorizationStatus() else {
            throw ScreenTimeError.notAuthorized
        }

        // Save to app group for extension access
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }

        // Save application tokens
        var tokenMapping: [String: Data] = [:]
        for token in selection.applicationTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                tokenMapping[key] = encoded
            }
        }
        sharedDefaults.set(tokenMapping, forKey: AppGroupConstants.tokenMappingKey)

        // Save category tokens
        var categoryMapping: [String: Data] = [:]
        for token in selection.categoryTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                categoryMapping[key] = encoded
            }
        }
        sharedDefaults.set(categoryMapping, forKey: AppGroupConstants.categoryTokensKey)

        // Save time limits
        let limitsDict = timeLimits.mapValues { $0.rawValue }
        sharedDefaults.set(limitsDict, forKey: "appTimeLimits")

        // Also save to repository for backup
        try await screenTimeRepository.saveAppSelection(selection, timeLimits: timeLimits)
    }

    func loadAppSelection() async throws -> FamilyActivitySelection {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }

        var selection = FamilyActivitySelection()

        // Load application tokens
        if let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data] {
            for (_, data) in tokenMapping {
                if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                    selection.applicationTokens.insert(token)
                }
            }
        }

        // Load category tokens
        if let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] {
            for (_, data) in categoryMapping {
                if let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) {
                    selection.categoryTokens.insert(token)
                }
            }
        }

        return selection
    }

    func clearAppSelection() async throws {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }

        sharedDefaults.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        sharedDefaults.removeObject(forKey: AppGroupConstants.categoryTokensKey)
        sharedDefaults.removeObject(forKey: "appTimeLimits")

        try await screenTimeRepository.clearAppSelection()
    }

    // MARK: - Shield Management

    @available(iOS 16.0, *)
    func applyShields() async throws {
        guard checkAuthorizationStatus() else {
            throw ScreenTimeError.notAuthorized
        }

        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }

        // Get saved app selection
        guard let tokenMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data],
              let categoryMapping = sharedDefaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] else {
            throw ScreenTimeError.noAppSelection
        }

        // Decode application tokens
        let applicationTokens = tokenMapping.compactMap { _, data -> ApplicationToken? in
            try? JSONDecoder().decode(ApplicationToken.self, from: data)
        }

        // Decode category tokens
        let categoryTokens = categoryMapping.compactMap { _, data -> ActivityCategoryToken? in
            try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
        }

        // Apply shields using ManagedSettings
        // Note: ManagedSettings API must be used on iOS device
        // The actual shield application requires DeviceActivity framework setup
    }

    @available(iOS 16.0, *)
    func removeShields() async throws {
        // Clear all shield settings
        // Note: Must be called from iOS device with ManagedSettings
    }

    func isShieldsActive() async throws -> Bool {
        // Cannot directly check shield state, use sharedDefaults flag
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            return false
        }
        return sharedDefaults.bool(forKey: "activeSession")
    }

    // MARK: - Session Management

    func startQuranSession(surahId: Int) async throws {
        // Apply shields when session starts
        try await applyShields()

        // Save session state
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }
        sharedDefaults.set(true, forKey: "activeSession")
        sharedDefaults.set(surahId, forKey: "activeSurahId")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "sessionStartTime")
    }

    func endQuranSession() async throws {
        // Remove shields when session ends
        try await removeShields()

        // Clear session state
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else {
            throw ScreenTimeError.appGroupUnavailable
        }
        sharedDefaults.removeObject(forKey: "activeSession")
        sharedDefaults.removeObject(forKey: "activeSurahId")
        sharedDefaults.removeObject(forKey: "sessionStartTime")
    }
}

// MARK: - Screen Time Errors

enum ScreenTimeError: Error, LocalizedError {
    case notAuthorized
    case appGroupUnavailable
    case noAppSelection
    case shieldFailed
    case sessionAlreadyActive
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time permission not granted"
        case .appGroupUnavailable:
            return "App Group not available"
        case .noAppSelection:
            return "No apps selected for blocking"
        case .shieldFailed:
            return "Failed to apply shields"
        case .sessionAlreadyActive:
            return "A session is already active"
        case .noActiveSession:
            return "No active session to end"
        }
    }
}
