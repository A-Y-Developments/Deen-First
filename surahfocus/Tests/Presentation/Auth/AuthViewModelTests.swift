import XCTest
import AuthenticationServices
@testable import SurahFocus

@MainActor
final class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    func testCheckExistingUserReturnsTrue() async {
        mockAuthService.userToReturn = User(appleUserId: "test123")

        let hasUser = await viewModel.checkExistingUser()

        XCTAssertTrue(hasUser)
    }

    func testCheckExistingUserReturnsFalse() async {
        mockAuthService.userToReturn = nil

        let hasUser = await viewModel.checkExistingUser()

        XCTAssertFalse(hasUser)
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthService {
    var userToReturn: User?
    var shouldThrowError = false

    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        if shouldThrowError {
            throw AuthError.invalidCredential
        }
        let user = User(appleUserId: "mock123")
        userToReturn = user
        return user
    }

    func getCurrentUser() async throws -> User? {
        return userToReturn
    }

    func signOut() async throws {
        userToReturn = nil
    }
}
