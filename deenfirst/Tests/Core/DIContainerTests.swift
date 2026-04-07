import XCTest

@testable import DeenFirst

final class DIContainerTests: XCTestCase {

    func testDIContainerIsSingleton() {
        let instance1 = DIContainer.shared
        let instance2 = DIContainer.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testDIContainerCreatesDataSources() {
        let container = DIContainer.shared

        XCTAssertNotNil(container.localDataSource)
        XCTAssertNotNil(container.quranAPIDataSource)
    }

    func testDIContainerCreatesRepositories() {
        let container = DIContainer.shared

        XCTAssertNotNil(container.userRepository)
        XCTAssertNotNil(container.sessionRepository)
        XCTAssertNotNil(container.quranRepository)
        XCTAssertNotNil(container.screenTimeRulesRepository)
    }

    func testDIContainerCreatesServices() {
        let container = DIContainer.shared

        XCTAssertNotNil(container.authService)
        XCTAssertNotNil(container.subscriptionService)
        XCTAssertNotNil(container.quranService)
        XCTAssertNotNil(container.sessionService)
    }

    @MainActor
    func testTestContainerCreation() {
        let testContainer = DIContainer.makeTestContainer()

        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContainer.mainContext)
    }
}
