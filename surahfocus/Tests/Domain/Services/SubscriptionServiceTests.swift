import XCTest
@testable import SurahFocus

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    var mockUserRepository: MockUserRepositoryForSubscription!
    var subscriptionService: SubscriptionService!

    override func setUp() {
        mockUserRepository = MockUserRepositoryForSubscription()
        subscriptionService = SubscriptionServiceImpl(userRepository: mockUserRepository)
    }

    override func tearDown() {
        mockUserRepository = nil
        subscriptionService = nil
    }

    // Note: Full RevenueCat integration tests require sandbox environment
    // These are unit tests for the service logic only

    func testSubscriptionErrorDescriptions() {
        let packageError = SubscriptionError.packageNotFound("monthly")
        XCTAssertEqual(
            packageError.errorDescription,
            "Subscription package 'monthly' not found"
        )

        let offeringsError = SubscriptionError.noOfferingsAvailable
        XCTAssertEqual(
            offeringsError.errorDescription,
            "No subscription offerings available"
        )
    }
}

// MARK: - Mock User Repository

class MockUserRepositoryForSubscription: UserRepository {
    var userToReturn: User?
    var didCallCreateUser = false
    var didCallDeleteCurrentUser = false
    var didCallUpdateUser = false

    func createUser(_ user: User) async throws {
        didCallCreateUser = true
    }

    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        return userToReturn
    }

    func getCurrentUser() async throws -> User? {
        return userToReturn
    }

    func updateUser(_ user: User) async throws {
        didCallUpdateUser = true
    }

    func deleteCurrentUser() async throws {
        didCallDeleteCurrentUser = true
    }
}
