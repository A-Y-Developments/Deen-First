import XCTest
@testable import SurahFocus

final class BlockedAppInfoTests: XCTestCase {

    func testBlockedAppInfoInitialization() {
        let tokenData = Data("test".utf8)
        let info = BlockedAppInfo(
            tokenData: tokenData,
            name: "TestApp",
            bundleId: "com.test.app",
            timeLimit: .thirty,
            limitType: .appLimit
        )

        XCTAssertEqual(info.name, "TestApp")
        XCTAssertEqual(info.bundleId, "com.test.app")
        XCTAssertEqual(info.timeLimit, .thirty)
        XCTAssertEqual(info.limitType, .appLimit)
    }

    func testDisplayName_ReturnsName_WhenNameNotEmpty() {
        let info = BlockedAppInfo(tokenData: Data(), name: "Music")
        XCTAssertEqual(info.displayName, "Music")
    }

    func testDisplayName_ReturnsApp_WhenNameEmpty() {
        let info = BlockedAppInfo(tokenData: Data(), name: "")
        XCTAssertEqual(info.displayName, "App")
    }

    func testTimeLimitDisplay_ReturnsCorrectFormat() {
        let info = BlockedAppInfo(tokenData: Data(), timeLimit: .thirty)
        XCTAssertEqual(info.timeLimitDisplay, "30 min")
    }

    func testTimeLimitDisplay_ReturnsOneHour() {
        let info = BlockedAppInfo(tokenData: Data(), timeLimit: .sixty)
        XCTAssertEqual(info.timeLimitDisplay, "1 hour")
    }

    func testLimitType_AppLimit() {
        let info = BlockedAppInfo(tokenData: Data(), limitType: .appLimit)
        XCTAssertEqual(info.limitType, .appLimit)
    }

    func testLimitType_TimeLimit() {
        let info = BlockedAppInfo(tokenData: Data(), limitType: .timeLimit)
        XCTAssertEqual(info.limitType, .timeLimit)
    }

    func testIdentifiable_Conformance() {
        let id = UUID()
        let info = BlockedAppInfo(id: id, tokenData: Data())
        XCTAssertEqual(info.id, id)
    }

    func testDefaultValues() {
        let info = BlockedAppInfo(tokenData: Data())
        XCTAssertEqual(info.name, "App")
        XCTAssertEqual(info.bundleId, "")
        XCTAssertEqual(info.timeLimit, .sixty)
        XCTAssertEqual(info.limitType, .appLimit)
    }
}
