import XCTest
import FamilyControls
@testable import SurahFocus

@MainActor
final class ScreenTimeServiceTests: XCTestCase {
    var mockRepository: MockScreenTimeRepositoryForService!
    var service: ScreenTimeServiceImpl!

    override func setUp() {
        super.setUp()
        mockRepository = MockScreenTimeRepositoryForService()
        service = ScreenTimeServiceImpl(screenTimeRepository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        service = nil
        super.tearDown()
    }

    func testGetBlockedAppsInfo_ReturnsEmptyArray_WhenNoApps() async throws {
        mockRepository.blockedAppsToReturn = []

        let result = try await service.getBlockedAppsInfo(userId: UUID())

        XCTAssertTrue(result.isEmpty)
    }

    func testGetBlockedAppsInfo_ReturnsApps_WithDefaults() async throws {
        let userId = UUID()
        let tokenData = Data("test".utf8)
        let blockedApp = BlockedApp(
            userId: userId,
            appTokenData: tokenData,
            appName: "",
            bundleIdentifier: "com.test.app",
            dailyLimitMinutes: 60
        )
        mockRepository.blockedAppsToReturn = [blockedApp]

        let result = try await service.getBlockedAppsInfo(userId: userId)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.tokenData, tokenData)
        XCTAssertEqual(result.first?.name, "App 1")
        XCTAssertEqual(result.first?.bundleId, "com.test.app")
    }

    func testGetBlockedAppsInfo_UsesAppName_WhenProvided() async throws {
        let userId = UUID()
        let tokenData = Data("test".utf8)
        let blockedApp = BlockedApp(
            userId: userId,
            appTokenData: tokenData,
            appName: "Music",
            bundleIdentifier: "com.test.app",
            dailyLimitMinutes: 30
        )
        mockRepository.blockedAppsToReturn = [blockedApp]

        let result = try await service.getBlockedAppsInfo(userId: userId)

        XCTAssertEqual(result.first?.name, "Music")
    }

    func testRemoveAppFromBlocking_RemovesFromRepository() async throws {
        let userId = UUID()
        let tokenData = Data("test".utf8)
        let blockedApp = BlockedApp(
            userId: userId,
            appTokenData: tokenData,
            appName: "TestApp",
            bundleIdentifier: "com.test.app",
            dailyLimitMinutes: 60
        )
        mockRepository.blockedAppsToReturn = [blockedApp]

        try await service.removeAppFromBlocking(tokenData: tokenData, userId: userId)

        XCTAssertTrue(mockRepository.didCallDelete)
    }

    func testRemoveAppFromBlocking_DoesNotThrow_WhenAppNotFound() async throws {
        let userId = UUID()
        let tokenData = Data("nonexistent".utf8)
        mockRepository.blockedAppsToReturn = []

        try await service.removeAppFromBlocking(tokenData: tokenData, userId: userId)

        XCTAssertFalse(mockRepository.didCallDelete)
    }

    func testUpdateAppTimeLimit_UpdatesSharedDefaults() async throws {
        let tokenData = Data("test".utf8)

        try await service.updateAppTimeLimit(tokenData: tokenData, limit: .thirty)

        let sharedDefaults = AppGroupConstants.sharedDefaults
        let timeLimitsDict = sharedDefaults?.dictionary(forKey: "appTimeLimits") as? [String: Int]
        XCTAssertEqual(timeLimitsDict?[String(tokenData.hashValue)], 30)
    }

    // Note: testCheckAuthorizationStatus removed - requires actual Apple authorization in production environment
}

// MARK: - Mock Repository

class MockScreenTimeRepositoryForService: ScreenTimeRepository {
    var blockedAppsToReturn: [BlockedApp] = []
    var didCallDelete = false
    private let localDataSource = LocalDataSource(container: DIContainer.makeTestContainer().modelContainer)

    func saveAppSelection(_ selection: FamilyActivitySelection, timeLimits: [String: TimeLimit]) async throws {
    }

    func loadAppSelection() async throws -> FamilyActivitySelection {
        return FamilyActivitySelection()
    }

    func clearAppSelection() async throws {
    }

    func saveActiveSession(_ session: Session) async throws {
    }

    func loadActiveSession() async throws -> Session? {
        return nil
    }

    func clearActiveSession() async throws {
    }

    func getBlockedApps(for userId: UUID) async throws -> [BlockedApp] {
        return blockedAppsToReturn
    }

    func deleteBlockedApp(_ app: BlockedApp) async throws {
        didCallDelete = true
        try await MainActor.run {
            try localDataSource.deleteBlockedApp(app)
        }
    }
}
