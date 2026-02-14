import XCTest
import ManagedSettings
import FamilyControls
@testable import SurahFocus

@MainActor
final class ManagedSettingsWrapperTests: XCTestCase {
    var wrapper: ManagedSettingsWrapper!

    override func setUp() {
        wrapper = ManagedSettingsWrapper()
    }

    override func tearDown() {
        wrapper.removeAllShields()
        wrapper = nil
    }

    func testRemoveAllShields_ClearsApplications() {
        // Given - apply a shield first
        wrapper.store.shield.applications = []
        XCTAssertNotNil(wrapper.store.shield.applications)

        // When
        wrapper.removeAllShields()

        // Then
        XCTAssertNil(wrapper.store.shield.applications)
    }

    func testRemoveAllShields_ClearsCategories() {
        // Given
        wrapper.store.shield.applicationCategories = .specific([])
        XCTAssertNotNil(wrapper.store.shield.applicationCategories)

        // When
        wrapper.removeAllShields()

        // Then
        XCTAssertNil(wrapper.store.shield.applicationCategories)
    }

    func testRemoveAllShields_ClearsWebDomains() {
        // Given
        wrapper.store.shield.webDomains = []
        XCTAssertNotNil(wrapper.store.shield.webDomains)

        // When
        wrapper.removeAllShields()

        // Then
        XCTAssertNil(wrapper.store.shield.webDomains)
    }
}
