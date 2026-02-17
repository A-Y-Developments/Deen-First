import XCTest
import AuthenticationServices
import RevenueCat
@testable import SurahFocus

@MainActor
final class SettingsTabViewModelTests: XCTestCase {
    var viewModel: SettingsTabViewModel!
    var mockUserRepository: MockUserRepositoryForSettings!
    var mockAuthService: MockAuthServiceForSettings!
    var mockSubscriptionService: MockSubscriptionServiceForSettings!

    override func setUp() async throws {
        mockUserRepository = MockUserRepositoryForSettings()
        mockAuthService = MockAuthServiceForSettings()
        mockSubscriptionService = MockSubscriptionServiceForSettings()
        viewModel = SettingsTabViewModel(
            userRepository: mockUserRepository,
            authService: mockAuthService,
            subscriptionService: mockSubscriptionService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockUserRepository = nil
        mockAuthService = nil
        mockSubscriptionService = nil
    }

    func testLoadUserData_PopulatesUser() async throws {
        let user = User(appleUserId: "test123", email: "test@example.com", name: "Test User")
        mockUserRepository.userToReturn = user

        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.user?.email, "test@example.com")
        XCTAssertEqual(viewModel.user?.name, "Test User")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadUserData_SetsError_WhenRepositoryFails() async {
        mockUserRepository.shouldThrowError = true

        await viewModel.loadUserData()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDisplayName_ReturnsName_WhenNameExists() async throws {
        let user = User(appleUserId: "test", name: "John Doe")
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.displayName, "John Doe")
    }

    func testDisplayName_ReturnsUser_WhenNameNil() async throws {
        let user = User(appleUserId: "test", name: nil)
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.displayName, "User")
    }

    func testDisplayInitial_ReturnsFirstLetter() async throws {
        let user = User(appleUserId: "test", name: "Alice")
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.displayInitial, "A")
    }

    func testStreakText_ReturnsCorrectFormat() async throws {
        let user = User(appleUserId: "test")
        user.currentStreak = 5
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.streakText, "5 day streak")
    }

    func testSubscriptionStatusText_ReturnsPremium() async throws {
        let user = User(appleUserId: "test")
        user.isPremium = true
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.subscriptionStatusText, "Premium")
    }

    func testSubscriptionStatusText_ReturnsFree() async throws {
        let user = User(appleUserId: "test")
        user.isPremium = false
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertEqual(viewModel.subscriptionStatusText, "Free")
    }

    func testIsSubscribed_ReturnsTrue_WhenPremium() async throws {
        let user = User(appleUserId: "test")
        user.isPremium = true
        mockUserRepository.userToReturn = user
        await viewModel.loadUserData()

        XCTAssertTrue(viewModel.isSubscribed)
    }

    func testSignOut_CallsAuthService() async {
        await viewModel.signOut()

        XCTAssertTrue(mockAuthService.didCallSignOut)
    }

    func testDeleteAccount_DeletesUserAndSignsOut() async throws {
        let user = User(appleUserId: "test")
        mockUserRepository.userToReturn = user

        // First load the user data
        await viewModel.loadUserData()

        await viewModel.deleteAccount()

        XCTAssertTrue(mockUserRepository.didCallDelete)
        XCTAssertTrue(mockAuthService.didCallSignOut)
    }

    func testDeleteAccount_SetsError_WhenNoUser() async {
        mockUserRepository.userToReturn = nil

        await viewModel.deleteAccount()

        XCTAssertNotNil(viewModel.errorMessage)
    }
}

// MARK: - Mocks

class MockUserRepositoryForSettings: UserRepository {
    var userToReturn: User?
    var shouldThrowError = false
    var didCallDelete = false

    func createUser(_ user: User) async throws {
    }

    func getUser(byAppleUserId appleUserId: String) async throws -> User? {
        return userToReturn
    }

    func getCurrentUser() async throws -> User? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return userToReturn
    }

    func updateUser(_ user: User) async throws {
    }

    func deleteCurrentUser() async throws {
        didCallDelete = true
    }
}

class MockAuthServiceForSettings: AuthService {
    var didCallSignOut = false

    func getCurrentUser() async throws -> User? {
        return nil
    }

    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        return User(appleUserId: "test")
    }

    func signOut() async throws {
        didCallSignOut = true
    }
}

class MockSubscriptionServiceForSettings: SubscriptionService {
    func checkSubscriptionStatus() async throws -> Bool {
        return false
    }

    func fetchOfferings() async throws -> Offerings {
        throw NSError(domain: "Not implemented", code: 0)
    }

    func purchase(package: Package) async throws -> Bool {
        return false
    }

    func purchaseMonthly() async throws -> Bool {
        return false
    }

    func purchaseYearly() async throws -> Bool {
        return false
    }

    func restorePurchases() async throws -> Bool {
        return false
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        throw NSError(domain: "Not implemented", code: 0)
    }
}
