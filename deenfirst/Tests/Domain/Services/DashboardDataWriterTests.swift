import XCTest

@testable import DeenFirst

final class DashboardDataWriterTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var fixedDate: Date!
    private var writer: DashboardDataWriterImpl!

    override func setUp() {
        super.setUp()
        suiteName = "DashboardDataWriterTests.\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test suite defaults")
            return
        }
        defaults = suite
        // 2026-04-08 12:00:00 UTC — Wednesday of ISO week 15
        fixedDate = Date(timeIntervalSince1970: 1_775_995_200)
        writer = DashboardDataWriterImpl(defaults: defaults, now: { [unowned self] in self.fixedDate })
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        fixedDate = nil
        writer = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func currentDayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: fixedDate)
    }

    private func currentWeekKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "YYYY-'W'ww"
        return f.string(from: fixedDate)
    }

    // MARK: - recordFocusSession

    func testRecordFocusSession_bumpsCountAndSeconds() {
        writer.recordFocusSession(duration: 120)

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSessionsKey(day)), 1)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSecondsKey(day)), 120)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 120)
    }

    func testRecordFocusSession_accumulatesAdditively() {
        writer.recordFocusSession(duration: 60)
        writer.recordFocusSession(duration: 90)

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSessionsKey(day)), 2)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSecondsKey(day)), 150)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 150)
    }

    func testRecordFocusSession_ignoresZeroOrNegativeDuration() {
        writer.recordFocusSession(duration: 0)
        writer.recordFocusSession(duration: -5)

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSessionsKey(day)), 0)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSecondsKey(day)), 0)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 0)
    }

    // MARK: - recordQuranReading

    func testRecordQuranReading_addsDurationOnly() {
        writer.recordQuranReading(duration: 45)
        writer.recordQuranReading(duration: 15)

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 60)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.focusSessionsKey(day)), 0)
    }

    // MARK: - Recitations

    func testRecordRecitationPassed_incrementsPassedOnly() {
        writer.recordRecitationPassed()
        writer.recordRecitationPassed()

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.recitationsPassedKey(day)), 2)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.recitationsAttemptsKey(day)), 0)
    }

    func testRecordRecitationAttempt_incrementsAttemptsOnly() {
        writer.recordRecitationAttempt()

        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.recitationsAttemptsKey(day)), 1)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.recitationsPassedKey(day)), 0)
    }

    // MARK: - recordEmergencyUnblock

    func testRecordEmergencyUnblock_incrementsWeekKey() {
        writer.recordEmergencyUnblock()
        writer.recordEmergencyUnblock()

        let week = currentWeekKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.emergencyUnblocksKey(week)), 2)
    }

    // MARK: - updateStreak

    func testUpdateStreak_setsValuesDirectly() {
        writer.updateStreak(current: 7, longest: 12)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.streakCurrentKey), 7)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.streakLongestKey), 12)

        // Second call overwrites, does NOT add
        writer.updateStreak(current: 3, longest: 12)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.streakCurrentKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.streakLongestKey), 12)
    }

    // MARK: - dataLastUpdatedAt

    func testEveryWriteStampsDataLastUpdatedAt() {
        let before = defaults.string(forKey: AppGroupConstants.dataLastUpdatedAtKey)
        XCTAssertNil(before)

        writer.recordRecitationAttempt()
        let stamp = defaults.string(forKey: AppGroupConstants.dataLastUpdatedAtKey)
        XCTAssertNotNil(stamp)
        // ISO8601 format sanity check
        XCTAssertNotNil(ISO8601DateFormatter().date(from: stamp ?? ""))
    }

    func testFlush_stampsLastUpdatedAtWithoutChangingCounters() {
        writer.recordQuranReading(duration: 30)
        let day = currentDayKey()
        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 30)

        // Advance time, flush, assert stamp updated but counter preserved
        let laterDate = fixedDate.addingTimeInterval(3600)
        let laterWriter = DashboardDataWriterImpl(defaults: defaults, now: { laterDate })
        laterWriter.flush()

        XCTAssertEqual(defaults.integer(forKey: AppGroupConstants.quranSecondsKey(day)), 30)
        let stamp = defaults.string(forKey: AppGroupConstants.dataLastUpdatedAtKey)
        let parsed = ISO8601DateFormatter().date(from: stamp ?? "")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.timeIntervalSince1970 ?? 0, laterDate.timeIntervalSince1970, accuracy: 1)
    }
}
