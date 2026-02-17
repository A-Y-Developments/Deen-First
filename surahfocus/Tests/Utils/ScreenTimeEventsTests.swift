import XCTest
import DeviceActivity
import FamilyControls
@testable import SurahFocus

final class ScreenTimeEventsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear shared defaults before each test
        let sharedDefaults = AppGroupConstants.sharedDefaults
        sharedDefaults?.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        sharedDefaults?.removeObject(forKey: AppGroupConstants.categoryTokensKey)
    }

    override func tearDown() {
        // Clean up after each test
        let sharedDefaults = AppGroupConstants.sharedDefaults
        sharedDefaults?.removeObject(forKey: AppGroupConstants.tokenMappingKey)
        sharedDefaults?.removeObject(forKey: AppGroupConstants.categoryTokensKey)
        super.tearDown()
    }

    func testCreateEvents_WithApplicationTokens_CreatesCorrectEvents() {
        let token1 = AppLimitToken(id: UUID(), applicationToken: ApplicationToken(), categoryToken: nil)
        let token2 = AppLimitToken(id: UUID(), applicationToken: ApplicationToken(), categoryToken: nil)

        let events = ScreenTimeEvents.createEvents(for: .fifteen, selection: [token1, token2])

        XCTAssertEqual(events.count, 2)

        // Verify event names follow the pattern
        let eventNames = Array(events.keys)
        XCTAssertTrue(eventNames.allSatisfy { $0.rawValue.hasPrefix("limitReached_app_") })

        // Verify all events have the 15 minute threshold
        for event in events.values {
            XCTAssertEqual(event.threshold.second, 900) // 15 minutes = 900 seconds
        }
    }

    func testCreateEvents_WithCategoryTokens_CreatesCorrectEvents() {
        let token = AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: ActivityCategoryToken())

        let events = ScreenTimeEvents.createEvents(for: .sixty, selection: [token])

        XCTAssertEqual(events.count, 1)

        // Verify event name follows the pattern
        let eventName = events.keys.first
        XCTAssertTrue(eventName?.rawValue.hasPrefix("limitReached_category_") == true)

        // Verify threshold is 60 minutes
        let event = events.values.first
        XCTAssertEqual(event?.threshold.second, 3600) // 60 minutes = 3600 seconds
    }

    func testCreateEvents_WithMixedTokens_CreatesCorrectEvents() {
        let appToken = AppLimitToken(id: UUID(), applicationToken: ApplicationToken(), categoryToken: nil)
        let categoryToken = AppLimitToken(id: UUID(), applicationToken: nil, categoryToken: ActivityCategoryToken())

        let events = ScreenTimeEvents.createEvents(for: .thirty, selection: [appToken, categoryToken])

        XCTAssertEqual(events.count, 2)

        // Verify we have one app event and one category event
        let eventNames = Array(events.keys)
        XCTAssertEqual(eventNames.filter { $0.rawValue.hasPrefix("limitReached_app_") }.count, 1)
        XCTAssertEqual(eventNames.filter { $0.rawValue.hasPrefix("limitReached_category_") }.count, 1)
    }

    func testCreateEvents_SavesTokensToUserDefaults() {
        let tokenId = UUID()
        let token = AppLimitToken(id: tokenId, applicationToken: ApplicationToken(), categoryToken: nil)

        _ = ScreenTimeEvents.createEvents(for: .fifteen, selection: [token])

        // Verify token was saved to shared defaults
        let sharedDefaults = AppGroupConstants.sharedDefaults
        let tokenMapping = sharedDefaults?.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data]

        XCTAssertNotNil(tokenMapping)
        XCTAssertTrue(tokenMapping?.keys.contains(tokenId.uuidString) == true)
    }

    func testScreenTimeActivity_DailyMonitoring_CreatesCorrectName() {
        let ruleId = UUID()
        let activityName = ScreenTimeActivity.dailyMonitoring(for: ruleId)

        XCTAssertTrue(activityName.rawValue.hasPrefix("daily_"))
        XCTAssertTrue(activityName.rawValue.contains(ruleId.uuidString))
    }

    func testScreenTimeActivity_DailyMonitoring_WithDifferentIds_CreatesUniqueNames() {
        let id1 = UUID()
        let id2 = UUID()

        let name1 = ScreenTimeActivity.dailyMonitoring(for: id1)
        let name2 = ScreenTimeActivity.dailyMonitoring(for: id2)

        XCTAssertNotEqual(name1, name2)
    }
}
