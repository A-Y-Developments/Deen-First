import XCTest
import FamilyControls
@testable import SurahFocus

@MainActor
final class ScreenTimeRulesUseCaseTests: XCTestCase {
    var useCase: ScreenTimeRulesUseCaseImpl!
    var repository: ScreenTimeRulesRepositoryImpl!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        let suiteName = "test_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)

        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "timeOfDayRules")
        userDefaults.removeObject(forKey: "allDayRules")

        repository = ScreenTimeRulesRepositoryImpl(userDefaults: userDefaults)
        useCase = ScreenTimeRulesUseCaseImpl(repository: repository)
    }

    override func tearDown() async throws {
        userDefaults.removeObject(forKey: "timeLimitRules")
        userDefaults.removeObject(forKey: "timeOfDayRules")
        userDefaults.removeObject(forKey: "allDayRules")
        useCase = nil
        repository = nil
        userDefaults = nil
    }

    // MARK: - Time Limit Use Case Tests

    func testSetTimeLimit_CreatesRule() async throws {
        let selection = FamilyActivitySelection()
        let config = TimeLimitConfig(
            name: "Social Media",
            timeLimit: .oneHour,
            daysActive: []
        )

        try await useCase.setTimeLimit(for: selection, config: config)

        let rules = useCase.getTimeLimitRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Social Media")
    }

    func testSetTimeLimit_WithCustomDuration() async throws {
        let selection = FamilyActivitySelection()
        let config = TimeLimitConfig(
            name: "Custom",
            timeLimit: .custom(5400), // 1.5 hours
            daysActive: []
        )

        try await useCase.setTimeLimit(for: selection, config: config)

        let rules = useCase.getTimeLimitRules()
        XCTAssertEqual(rules.first?.limitSeconds, 5400)
    }

    func testDeleteTimeLimit_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let config = TimeLimitConfig(
            name: "Test",
            timeLimit: .thirtyMin,
            daysActive: []
        )

        try await useCase.setTimeLimit(for: selection, config: config)
        XCTAssertEqual(useCase.getTimeLimitRules().count, 1)

        let rule = useCase.getTimeLimitRules().first!
        try await useCase.deleteTimeLimit(id: rule.id)

        XCTAssertEqual(useCase.getTimeLimitRules().count, 0)
    }

    // MARK: - Time of Day Use Case Tests

    func testSetTimeOfDayBlock_CreatesRule() async throws {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)
        let config = TimeOfDayConfig(
            name: "Work Hours",
            startTime: start,
            endTime: end,
            daysActive: []
        )

        try await useCase.setTimeOfDayBlock(for: selection, config: config)

        let rules = useCase.getTimeOfDayRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Work Hours")
    }

    func testSetTimeOfDayBlock_WithSpecificDays() async throws {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)
        let config = TimeOfDayConfig(
            name: "Weekdays",
            startTime: start,
            endTime: end,
            daysActive: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        )

        try await useCase.setTimeOfDayBlock(for: selection, config: config)

        let rules = useCase.getTimeOfDayRules()
        XCTAssertEqual(rules.first?.daysActive?.count, 5)
    }

    func testDeleteTimeOfDay_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 0)
        let config = TimeOfDayConfig(
            name: "Test",
            startTime: start,
            endTime: end,
            daysActive: []
        )

        try await useCase.setTimeOfDayBlock(for: selection, config: config)
        XCTAssertEqual(useCase.getTimeOfDayRules().count, 1)

        let rule = useCase.getTimeOfDayRules().first!
        try await useCase.deleteTimeOfDay(id: rule.id)

        XCTAssertEqual(useCase.getTimeOfDayRules().count, 0)
    }

    // MARK: - All Day Use Case Tests

    func testSetAllDayBlock_CreatesRule() async throws {
        let selection = FamilyActivitySelection()
        let config = AllDayConfig(
            name: "Weekend",
            daysActive: ["Saturday", "Sunday"]
        )

        try await useCase.setAllDayBlock(for: selection, config: config)

        let rules = useCase.getAllDayRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.name, "Weekend")
    }

    func testSetAllDayBlock_WithEmptyDaysMeansAllDays() async throws {
        let selection = FamilyActivitySelection()
        let config = AllDayConfig(
            name: "Everyday",
            daysActive: []
        )

        try await useCase.setAllDayBlock(for: selection, config: config)

        let rules = useCase.getAllDayRules()
        // Empty days should be treated as all days
        XCTAssertEqual(rules.count, 1)
    }

    func testDeleteAllDay_RemovesRule() async throws {
        let selection = FamilyActivitySelection()
        let config = AllDayConfig(
            name: "Test",
            daysActive: ["Saturday"]
        )

        try await useCase.setAllDayBlock(for: selection, config: config)
        XCTAssertEqual(useCase.getAllDayRules().count, 1)

        let rule = useCase.getAllDayRules().first!
        try await useCase.deleteAllDay(id: rule.id)

        XCTAssertEqual(useCase.getAllDayRules().count, 0)
    }

    // MARK: - Get All Rules Tests

    func testGetAllRules_ReturnsMixedTypes() async throws {
        let selection = FamilyActivitySelection()

        // Create one of each type
        let timeLimitConfig = TimeLimitConfig(
            name: "Limit",
            timeLimit: .oneHour,
            daysActive: []
        )

        let timeOfDayConfig = TimeOfDayConfig(
            name: "Downtime",
            startTime: DateComponents(hour: 9, minute: 0),
            endTime: DateComponents(hour: 17, minute: 0),
            daysActive: []
        )

        let allDayConfig = AllDayConfig(
            name: "All Day",
            daysActive: []
        )

        try await useCase.setTimeLimit(for: selection, config: timeLimitConfig)
        try await useCase.setTimeOfDayBlock(for: selection, config: timeOfDayConfig)
        try await useCase.setAllDayBlock(for: selection, config: allDayConfig)

        let allRules = useCase.getAllRules()
        XCTAssertEqual(allRules.count, 3)

        let types = Set(allRules.map { $0.type })
        XCTAssertEqual(types.count, 3)
        XCTAssertTrue(types.contains(.timeLimit))
        XCTAssertTrue(types.contains(.timeOfDay))
        XCTAssertTrue(types.contains(.allDay))
    }

    func testGetAllRules_SortedByCreationDate() async throws {
        let selection = FamilyActivitySelection()

        // Create rules with delays to ensure different creation times
        let config1 = TimeLimitConfig(name: "First", timeLimit: .thirtyMin, daysActive: [])
        try await useCase.setTimeLimit(for: selection, config: config1)

        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        let config2 = TimeLimitConfig(name: "Second", timeLimit: .oneHour, daysActive: [])
        try await useCase.setTimeLimit(for: selection, config: config2)

        let rules = useCase.getTimeLimitRules()
        XCTAssertEqual(rules.count, 2)

        // First should be before second
        XCTAssertTrue(rules[0].createdAt <= rules[1].createdAt)
    }
}
