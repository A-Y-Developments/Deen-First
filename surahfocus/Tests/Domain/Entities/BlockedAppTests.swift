import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class BlockedAppTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([BlockedApp.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testBlockedAppInitialization() {
        let userId = UUID()
        let tokenData = "mocktoken".data(using: .utf8)!

        let app = BlockedApp(
            userId: userId,
            appTokenData: tokenData,
            appName: "Instagram",
            bundleIdentifier: "com.instagram.app",
            dailyLimitMinutes: 30
        )

        XCTAssertNotNil(app.id)
        XCTAssertEqual(app.userId, userId)
        XCTAssertEqual(app.appName, "Instagram")
        XCTAssertEqual(app.bundleIdentifier, "com.instagram.app")
        XCTAssertEqual(app.dailyLimitMinutes, 30)
        XCTAssertTrue(app.isActive)
    }

    func testBlockedAppDefaultsToActive() {
        let app = BlockedApp(
            userId: UUID(),
            appTokenData: Data(),
            appName: "TikTok",
            bundleIdentifier: "com.tiktok.app",
            dailyLimitMinutes: 15
        )

        XCTAssertTrue(app.isActive)
    }

    func testPersistenceInSwiftData() throws {
        let app = BlockedApp(
            userId: UUID(),
            appTokenData: Data(),
            appName: "Twitter",
            bundleIdentifier: "com.twitter.app",
            dailyLimitMinutes: 45
        )
        context.insert(app)
        try context.save()

        let fetchDescriptor = FetchDescriptor<BlockedApp>()
        let apps = try context.fetch(fetchDescriptor)

        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps.first?.appName, "Twitter")
    }
}
