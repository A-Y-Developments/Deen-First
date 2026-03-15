import XCTest

@testable import DeenFirst

@MainActor
final class RouterTests: XCTestCase {
    var router: Router!

    override func setUp() {
        router = Router()
    }

    override func tearDown() {
        router = nil
    }

    func testInitialPathIsEmpty() {
        XCTAssertEqual(router.navigationPath.count, 0)
    }

    func testNavigateAddsRoute() {
        router.navigate(to: .onboarding)

        XCTAssertEqual(router.navigationPath.count, 1)
    }

    func testNavigateMultipleRoutes() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        router.navigate(to: .mainTabs)

        XCTAssertEqual(router.navigationPath.count, 3)
    }

    func testNavigateBackRemovesLastRoute() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)

        router.navigateBack()

        XCTAssertEqual(router.navigationPath.count, 1)
    }

    func testNavigateBackOnEmptyPathDoesNothing() {
        router.navigateBack()

        XCTAssertEqual(router.navigationPath.count, 0)
    }

    func testReplaceWithClearsPathAndAddsNewRoute() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)

        router.replaceWith(.mainTabs)

        XCTAssertEqual(router.navigationPath.count, 1)
    }

    func testResetClearsAllRoutes() {
        router.navigate(to: .onboarding)
        router.navigate(to: .paywall)
        router.navigate(to: .mainTabs)

        router.reset()

        XCTAssertEqual(router.navigationPath.count, 0)
    }
}
