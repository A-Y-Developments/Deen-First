import XCTest

@testable import DeenFirst

final class DeenScoreMessageTests: XCTestCase {
    func test_excellent_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 100), "Excellent day. Masha'Allah, keep this up.")
        XCTAssertEqual(DeenScoreMessage.message(for: 95), "Excellent day. Masha'Allah, keep this up.")
        XCTAssertEqual(DeenScoreMessage.message(for: 90), "Excellent day. Masha'Allah, keep this up.")
    }

    func test_strong_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 89), "Strong day. Your consistency is showing.")
        XCTAssertEqual(DeenScoreMessage.message(for: 80), "Strong day. Your consistency is showing.")
    }

    func test_good_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 79), "Good day! A bit more Quran tomorrow.")
        XCTAssertEqual(DeenScoreMessage.message(for: 70), "Good day! A bit more Quran tomorrow.")
    }

    func test_decent_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 69), "Decent balance. Push for one more session.")
        XCTAssertEqual(DeenScoreMessage.message(for: 60), "Decent balance. Push for one more session.")
    }

    func test_average_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 59), "Average day. More Quran or less screen time.")
        XCTAssertEqual(DeenScoreMessage.message(for: 50), "Average day. More Quran or less screen time.")
    }

    func test_tough_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 49), "Tough balance. One focus session can turn this around.")
        XCTAssertEqual(DeenScoreMessage.message(for: 40), "Tough balance. One focus session can turn this around.")
    }

    func test_heavy_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 39), "Heavy phone use. Reset with 10 minutes of Quran.")
        XCTAssertEqual(DeenScoreMessage.message(for: 30), "Heavy phone use. Reset with 10 minutes of Quran.")
    }

    func test_difficult_range() {
        XCTAssertEqual(DeenScoreMessage.message(for: 29), "Difficult day. Don't give up — tomorrow is a fresh start.")
        XCTAssertEqual(DeenScoreMessage.message(for: 0), "Difficult day. Don't give up — tomorrow is a fresh start.")
    }
}
