import FamilyControls
import XCTest

@testable import DeenFirst

@MainActor
final class ScreenTimeRulesRepositoryTests: XCTestCase {
    var repository: ScreenTimeRulesRepositoryImpl!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        // Use a unique suite name for each test to avoid conflicts
        let suiteName = "test_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)

        // Clear any existing data
        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "allDayRules")

        repository = ScreenTimeRulesRepositoryImpl(userDefaults: userDefaults)
    }

    override func tearDown() async throws {
        // Clean up
        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "allDayRules")
        repository = nil
        userDefaults = nil
    }

    // MARK: - Time Limit Rules Tests

    func testSetTimeLimitRule_SavesRule() async throws {
        let selection = FamilyActivitySelection()
        let rule = ScreenTimeRule(
            name: "Social Media",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )

        repository.setTimeLimitRule(rule)

        let rules = repository.getTimeLimitRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Social Media")
        XCTAssertEqual(rules.first?.limitSeconds, 3600)
    }

    func testSetTimeLimitRule_MultipleRules_SavesAll() async throws {
        let selection = FamilyActivitySelection()

        let rule1 = ScreenTimeRule(
            name: "Twitter",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 1800
        )

        let rule2 = ScreenTimeRule(
            name: "Instagram",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )

        repository.setTimeLimitRule(rule1)
        repository.setTimeLimitRule(rule2)

        let rules = repository.getTimeLimitRules()
        XCTAssertEqual(rules.count, 2)
    }

    func testDeleteTimeLimitRule_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let rule = ScreenTimeRule(
            name: "Test",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )

        repository.setTimeLimitRule(rule)
        XCTAssertEqual(repository.getTimeLimitRules().count, 1)

        repository.deleteTimeLimitRule(id: rule.id)
        XCTAssertEqual(repository.getTimeLimitRules().count, 0)
    }

    // MARK: - Time of Day Rules Tests

    func testSettimeLimitRule_SavesRule() async throws {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)

        let rule = ScreenTimeRule(
            name: "Work Hours",
            selection: selection,
            type: .timeLimit,
            startTime: start,
            endTime: end
        )

        repository.settimeLimitRule(rule)

        let rules = repository.gettimeLimitRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Work Hours")
    }

    func testDeletetimeLimitRule_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)

        let rule = ScreenTimeRule(
            name: "Work",
            selection: selection,
            type: .timeLimit,
            startTime: start,
            endTime: end
        )

        repository.settimeLimitRule(rule)
        XCTAssertEqual(repository.gettimeLimitRules().count, 1)

        repository.deletetimeLimitRule(id: rule.id)
        XCTAssertEqual(repository.gettimeLimitRules().count, 0)
    }

    // MARK: - All Day Rules Tests

    func testSetAllDayRule_SavesRule() async throws {
        let selection = FamilyActivitySelection()
        let days: Set<String> = ["Saturday", "Sunday"]

        let rule = ScreenTimeRule(
            name: "Weekend",
            selection: selection,
            type: .allDay,
            daysActive: days
        )

        repository.setAllDayRule(rule)

        let rules = repository.getAllDayRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Weekend")
    }

    func testDeleteAllDayRule_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let rule = ScreenTimeRule(
            name: "Weekend",
            selection: selection,
            type: .allDay,
            daysActive: ["Saturday", "Sunday"]
        )

        repository.setAllDayRule(rule)
        XCTAssertEqual(repository.getAllDayRules().count, 1)

        repository.deleteAllDayRule(id: rule.id)
        XCTAssertEqual(repository.getAllDayRules().count, 0)
    }

    // MARK: - Get All Rules Tests

    func testGetAllRules_ReturnsAllRuleTypes() async throws {
        let selection = FamilyActivitySelection()

        let timeLimitRule = ScreenTimeRule(
            name: "Limit",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )

        let timeLimitRule = ScreenTimeRule(
            name: "Downtime",
            selection: selection,
            type: .timeLimit,
            startTime: DateComponents(hour: 9, minute: 0),
            endTime: DateComponents(hour: 17, minute: 0)
        )

        let allDayRule = ScreenTimeRule(
            name: "All Day",
            selection: selection,
            type: .allDay
        )

        repository.setTimeLimitRule(timeLimitRule)
        repository.settimeLimitRule(timeLimitRule)
        repository.setAllDayRule(allDayRule)

        let allRules = repository.getAllRules()
        XCTAssertEqual(allRules.count, 3)

        let types = Set(allRules.map { $0.type })
        XCTAssertTrue(types.contains(.timeLimit))
        XCTAssertTrue(types.contains(.timeLimit))
        XCTAssertTrue(types.contains(.allDay))
    }

    func testGetAllRules_EmptyWhenNoRules() async throws {
        let allRules = repository.getAllRules()
        XCTAssertTrue(allRules.isEmpty)
    }
}
