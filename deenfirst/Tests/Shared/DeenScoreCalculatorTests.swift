import XCTest

@testable import DeenFirst

final class DeenScoreCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func input(
        quranSeconds: Int = 0,
        focusSessions: Int = 0,
        recitationsPassed: Int = 0,
        streakDays: Int = 0,
        screenTimeOverLimitSeconds: Int = 0,
        emergencyUnblocksThisWeek: Int = 0
    ) -> DeenScoreInput {
        DeenScoreInput(
            quranSeconds: quranSeconds,
            focusSessions: focusSessions,
            recitationsPassed: recitationsPassed,
            streakDays: streakDays,
            screenTimeOverLimitSeconds: screenTimeOverLimitSeconds,
            emergencyUnblocksThisWeek: emergencyUnblocksThisWeek
        )
    }

    // MARK: - Base score

    func test_baseScore_withNoActivity_is50() {
        XCTAssertEqual(calculateDeenScore(input()), 50)
    }

    // MARK: - Clamping

    func test_maxScore_clampedTo100() {
        // 50 base + 20 quran + 15 focus + 10 recitation + 10 streak = 105 → 100
        let result = calculateDeenScore(
            input(
                quranSeconds: 30 * 60,
                focusSessions: 2,
                recitationsPassed: 3,
                streakDays: 7
            )
        )
        XCTAssertEqual(result, 100)
    }

    func test_minReachableScore_withMaxNegatives_is10() {
        // 50 base - 30 (90+ min over) - 10 (2+ emergencies) = 10.
        // Floor clamp itself is covered by `test_scoreNeverGoesBelow0`.
        let result = calculateDeenScore(
            input(
                screenTimeOverLimitSeconds: 90 * 60,
                emergencyUnblocksThisWeek: 2
            )
        )
        XCTAssertEqual(result, 10)
    }

    func test_scoreNeverExceeds100() {
        let result = calculateDeenScore(
            input(
                quranSeconds: 10 * 60 * 60,
                focusSessions: 50,
                recitationsPassed: 50,
                streakDays: 365
            )
        )
        XCTAssertLessThanOrEqual(result, 100)
        XCTAssertEqual(result, 100)
    }

    func test_scoreNeverGoesBelow0() {
        let result = calculateDeenScore(
            input(
                screenTimeOverLimitSeconds: 24 * 60 * 60,
                emergencyUnblocksThisWeek: 100
            )
        )
        XCTAssertGreaterThanOrEqual(result, 0)
    }

    // MARK: - Quran time (positives in isolation)

    func test_quranTime_zero_addsNothing() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 0)), 50)
    }

    func test_quranTime_under10min_adds5() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 5 * 60)), 55)
    }

    func test_quranTime_exactly10min_adds10() {
        // Boundary: 600 seconds is NOT < 600, so falls into next tier.
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 10 * 60)), 60)
    }

    func test_quranTime_under20min_adds10() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 15 * 60)), 60)
    }

    func test_quranTime_exactly20min_adds15() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 20 * 60)), 65)
    }

    func test_quranTime_under30min_adds15() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 25 * 60)), 65)
    }

    func test_quranTime_exactly30min_adds20() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 30 * 60)), 70)
    }

    func test_quranTime_over30min_adds20() {
        XCTAssertEqual(calculateDeenScore(input(quranSeconds: 60 * 60)), 70)
    }

    // MARK: - Focus sessions

    func test_focusSessions_zero_addsNothing() {
        XCTAssertEqual(calculateDeenScore(input(focusSessions: 0)), 50)
    }

    func test_focusSessions_one_adds10() {
        XCTAssertEqual(calculateDeenScore(input(focusSessions: 1)), 60)
    }

    func test_focusSessions_two_adds15() {
        XCTAssertEqual(calculateDeenScore(input(focusSessions: 2)), 65)
    }

    func test_focusSessions_manyPlus_adds15() {
        XCTAssertEqual(calculateDeenScore(input(focusSessions: 10)), 65)
    }

    // MARK: - Recitations

    func test_recitations_zero_addsNothing() {
        XCTAssertEqual(calculateDeenScore(input(recitationsPassed: 0)), 50)
    }

    func test_recitations_one_adds5() {
        XCTAssertEqual(calculateDeenScore(input(recitationsPassed: 1)), 55)
    }

    func test_recitations_two_adds5() {
        XCTAssertEqual(calculateDeenScore(input(recitationsPassed: 2)), 55)
    }

    func test_recitations_three_adds10() {
        XCTAssertEqual(calculateDeenScore(input(recitationsPassed: 3)), 60)
    }

    func test_recitations_manyPlus_adds10() {
        XCTAssertEqual(calculateDeenScore(input(recitationsPassed: 20)), 60)
    }

    // MARK: - Streak

    func test_streak_zero_addsNothing() {
        XCTAssertEqual(calculateDeenScore(input(streakDays: 0)), 50)
    }

    func test_streak_oneDay_adds5() {
        XCTAssertEqual(calculateDeenScore(input(streakDays: 1)), 55)
    }

    func test_streak_sixDays_adds5() {
        XCTAssertEqual(calculateDeenScore(input(streakDays: 6)), 55)
    }

    func test_streak_sevenDays_adds10WithBonus() {
        XCTAssertEqual(calculateDeenScore(input(streakDays: 7)), 60)
    }

    func test_streak_overSevenDays_adds10WithBonus() {
        XCTAssertEqual(calculateDeenScore(input(streakDays: 30)), 60)
    }

    // MARK: - Over-limit screen time (negatives in isolation)

    func test_overLimit_zero_subtractsNothing() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 0)), 50)
    }

    func test_overLimit_under30min_subtractsNothing() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 15 * 60)), 50)
    }

    func test_overLimit_exactly30min_subtracts10() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 30 * 60)), 40)
    }

    func test_overLimit_under60min_subtracts10() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 45 * 60)), 40)
    }

    func test_overLimit_exactly60min_subtracts20() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 60 * 60)), 30)
    }

    func test_overLimit_under90min_subtracts20() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 75 * 60)), 30)
    }

    func test_overLimit_exactly90min_subtracts30() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 90 * 60)), 20)
    }

    func test_overLimit_over90min_subtracts30() {
        XCTAssertEqual(calculateDeenScore(input(screenTimeOverLimitSeconds: 180 * 60)), 20)
    }

    // MARK: - Emergency unblocks

    func test_emergencyUnblocks_zero_subtractsNothing() {
        XCTAssertEqual(calculateDeenScore(input(emergencyUnblocksThisWeek: 0)), 50)
    }

    func test_emergencyUnblocks_one_subtracts5() {
        XCTAssertEqual(calculateDeenScore(input(emergencyUnblocksThisWeek: 1)), 45)
    }

    func test_emergencyUnblocks_two_subtracts10() {
        XCTAssertEqual(calculateDeenScore(input(emergencyUnblocksThisWeek: 2)), 40)
    }

    func test_emergencyUnblocks_manyPlus_subtracts10() {
        XCTAssertEqual(calculateDeenScore(input(emergencyUnblocksThisWeek: 10)), 40)
    }

    // MARK: - Combined scenarios

    func test_combinedPositivesAndNegatives() {
        // 50 + 10 (15min Quran) + 10 (1 session) + 5 (1 recitation)
        //    + 5 (3-day streak) - 10 (45min over) - 5 (1 emergency) = 65
        let result = calculateDeenScore(
            input(
                quranSeconds: 15 * 60,
                focusSessions: 1,
                recitationsPassed: 1,
                streakDays: 3,
                screenTimeOverLimitSeconds: 45 * 60,
                emergencyUnblocksThisWeek: 1
            )
        )
        XCTAssertEqual(result, 65)
    }
}
