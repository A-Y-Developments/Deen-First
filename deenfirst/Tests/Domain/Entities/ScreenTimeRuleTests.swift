import FamilyControls
import XCTest

@testable import DeenFirst

final class ScreenTimeRuleTests: XCTestCase {

    // MARK: - ScreenTimeRule Tests

    func testScreenTimeRuleInitializationForTimeLimit() {
        let selection = FamilyActivitySelection()
        let id = UUID()

        let rule = ScreenTimeRule(
            id: id,
            name: "Test Limit",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )

        XCTAssertEqual(rule.id, id)
        XCTAssertEqual(rule.name, "Test Limit")
        XCTAssertEqual(rule.type, .timeLimit)
        XCTAssertEqual(rule.limitSeconds, 3600)
        XCTAssertNil(rule.startTime)
        XCTAssertNil(rule.endTime)
    }

    func testScreenTimeRuleInitializationFortimeLimit() {
        let selection = FamilyActivitySelection()
        let startComponents = DateComponents(hour: 9, minute: 0)
        let endComponents = DateComponents(hour: 17, minute: 0)

        let rule = ScreenTimeRule(
            name: "Work Hours",
            selection: selection,
            type: .timeLimit,
            startTime: startComponents,
            endTime: endComponents
        )

        XCTAssertEqual(rule.name, "Work Hours")
        XCTAssertEqual(rule.type, .timeLimit)
        XCTAssertNotNil(rule.startTime)
        XCTAssertNotNil(rule.endTime)
        XCTAssertEqual(rule.startTime?.hour, 9)
        XCTAssertEqual(rule.endTime?.hour, 17)
    }

    func testScreenTimeRuleInitializationForAllDay() {
        let selection = FamilyActivitySelection()
        let daysActive: Set<String> = ["Monday", "Tuesday", "Wednesday"]

        let rule = ScreenTimeRule(
            name: "Week Day Block",
            selection: selection,
            type: .appLimit,
            daysActive: daysActive
        )

        XCTAssertEqual(rule.name, "Week Day Block")
        XCTAssertEqual(rule.type, .appLimit)
        XCTAssertEqual(rule.daysActive, daysActive)
    }

    func testScreenTimeRuleDaysActiveProperty() {
        let selection = FamilyActivitySelection()
        let days: Set<String> = ["Sunday", "Saturday"]

        let rule = ScreenTimeRule(
            name: "Weekend",
            selection: selection,
            type: .appLimit,
            daysActive: days
        )

        XCTAssertEqual(rule.daysActive?.count, 2)
        XCTAssertTrue(rule.daysActive?.contains("Sunday") == true)
        XCTAssertTrue(rule.daysActive?.contains("Saturday") == true)
    }

    func testScreenTimeRuleIsTodayActive() {
        let selection = FamilyActivitySelection()

        // Test with empty days (should be active)
        let rule1 = ScreenTimeRule(
            name: "Everyday",
            selection: selection,
            type: .appLimit,
            daysActive: []
        )
        XCTAssertTrue(rule1.isTodayActive)

        // Test with specific day
        let todayName = DayHelper.getCurrentDayName()
        let rule2 = ScreenTimeRule(
            name: "Today",
            selection: selection,
            type: .appLimit,
            daysActive: [todayName]
        )
        XCTAssertTrue(rule2.isTodayActive)
    }

    func testScreenTimeRuleLimitDisplayName() {
        let selection = FamilyActivitySelection()

        let rule1 = ScreenTimeRule(
            name: "1 Hour",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 3600
        )
        XCTAssertEqual(rule1.limitDisplayName, "1h/day")

        let rule2 = ScreenTimeRule(
            name: "30 Min",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 1800
        )
        XCTAssertEqual(rule2.limitDisplayName, "30m/day")

        let rule3 = ScreenTimeRule(
            name: "1h 30m",
            selection: selection,
            type: .timeLimit,
            limitSeconds: 5400
        )
        XCTAssertEqual(rule3.limitDisplayName, "1h 30m/day")
    }

    func testScreenTimeRuleTimeRangeDisplay() {
        let selection = FamilyActivitySelection()
        let start = DateComponents(hour: 9, minute: 0)
        let end = DateComponents(hour: 17, minute: 30)

        let rule = ScreenTimeRule(
            name: "Work",
            selection: selection,
            type: .timeLimit,
            startTime: start,
            endTime: end
        )

        let display = rule.timeRangeDisplay
        XCTAssertNotNil(display)
        XCTAssertTrue(display!.contains("9"))
        XCTAssertTrue(display!.contains("5"))
    }

    func testScreenTimeRuleDaysDisplayText() {
        let selection = FamilyActivitySelection()

        // Empty days
        let rule1 = ScreenTimeRule(
            name: "All",
            selection: selection,
            type: .appLimit,
            daysActive: []
        )
        XCTAssertEqual(rule1.daysDisplayText, "Everyday")

        // Specific days
        let rule2 = ScreenTimeRule(
            name: "Weekdays",
            selection: selection,
            type: .appLimit,
            daysActive: ["Monday", "Tuesday", "Wednesday"]
        )
        XCTAssertTrue(rule2.daysDisplayText.contains("Mon"))
        XCTAssertTrue(rule2.daysDisplayText.contains("Tue"))
        XCTAssertTrue(rule2.daysDisplayText.contains("Wed"))
    }
}
