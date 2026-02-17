import Foundation
import SwiftData
import FamilyControls
import DeviceActivity

// MARK: - Screen Time Repository Protocol

protocol ScreenTimeRepository {
    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws
    func loadAppSelection() async throws -> FamilyActivitySelection
    func clearAppSelection() async throws
    func saveActiveSession(_ session: Session) async throws
    func loadActiveSession() async throws -> Session?
    func clearActiveSession() async throws
    func getBlockedApps(for userId: UUID) async throws -> [BlockedApp]
    func deleteBlockedApp(_ app: BlockedApp) async throws

    // MARK: - Device Activity Monitoring

    func startActivityMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws
    func stopActivityMonitoring(_ names: Set<DeviceActivityName>) async throws
}

// MARK: - Screen Time Repository Implementation

final class ScreenTimeRepositoryImpl: ScreenTimeRepository {
    let localDataSource: LocalDataSource
    private let activityCenter = DeviceActivityCenter()

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    // MARK: - App Selection

    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws {
        // Data is primarily stored in App Group UserDefaults by the service layer
        // Repository just tracks metadata, not the opaque tokens
    }

    func loadAppSelection() async throws -> FamilyActivitySelection {
        // Return empty selection - actual data loaded from UserDefaults by service
        return FamilyActivitySelection()
    }

    func clearAppSelection() async throws {
        // Clear all BlockedApp records
        do {
            let apps = try await MainActor.run {
                try localDataSource.getAllBlockedApps()
            }

            for app in apps {
                try await MainActor.run {
                    try localDataSource.deleteBlockedApp(app)
                }
            }
        } catch {
            // Ignore if no apps exist
        }
    }

    // MARK: - Session Management

    func saveActiveSession(_ session: Session) async throws {
        try await MainActor.run {
            try localDataSource.insertSession(session)
        }
    }

    func loadActiveSession() async throws -> Session? {
        try await MainActor.run {
            try localDataSource.getActiveSession()
        }
    }

    func clearActiveSession() async throws {
        guard let session = try await loadActiveSession() else { return }
        try await MainActor.run {
            try localDataSource.deleteSession(session)
        }
    }

    func getBlockedApps(for userId: UUID) async throws -> [BlockedApp] {
        try await MainActor.run {
            try localDataSource.getAllBlockedApps()
        }
    }

    func deleteBlockedApp(_ app: BlockedApp) async throws {
        try await MainActor.run {
            try localDataSource.deleteBlockedApp(app)
        }
    }

    // MARK: - Device Activity Monitoring

    func startActivityMonitoring(
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule,
        events: [DeviceActivityEvent.Name: DeviceActivityEvent]
    ) async throws {
        try await MainActor.run {
            if !events.isEmpty {
                try activityCenter.startMonitoring(name, during: schedule, events: events)
            } else {
                try activityCenter.startMonitoring(name, during: schedule)
            }
        }
    }

    func stopActivityMonitoring(_ names: Set<DeviceActivityName>) async throws {
        try await MainActor.run {
            try activityCenter.stopMonitoring(Array(names))
        }
    }
}
