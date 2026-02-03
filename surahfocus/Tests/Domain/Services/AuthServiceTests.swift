import XCTest
import AuthenticationServices
@testable import SurahFocus

@MainActor
final class AuthServiceTests: XCTestCase {
    var mockUserRepository: MockUserRepositoryForAuth!
    var authService: AuthService!

    override func setUp() {
        mockUserRepository = MockUserRepositoryForAuth()
        authService = AuthServiceImpl(userRepository: mockUserRepository)
    }

    override func tearDown() {
        mockUserRepository = nil
        authService = nil
    }

    func testGetCurrentUserReturnsUser() async throws {
        let mockUser = User(appleUserId: "test123")
        mockUserRepository.userToReturn = mockUser

        let user = try await authService.getCurrentUser()

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.appleUserId, "test123")
    }

    func testGetCurrentUserReturnsNilWhenNoUser() async throws {
        mockUserRepository.userToReturn = nil

        let user = try await authService.getCurrentUser()

        XCTAssertNil(user)
    }

    func testSignOutDeletesUser() async throws {
        try await authService.signOut()

        XCTAssertTrue(mockUserRepository.didCallDeleteCurrentUser)
    }

    func testAuthErrorDescriptions() {
        XCTAssertEqual(
            AuthError.invalidCredential.errorDescription,
            "Invalid authentication credential"
        )
        XCTAssertEqual(
            AuthError.userNotFound.errorDescription,
            "User not found"
        )
        XCTAssertEqual(
            AuthError.cancelled.errorDescription,
            "Authentication was cancelled"
        )
    }
}

// MARK: - Mock Repository

class MockUserRepositoryForAuth: UserRepository {
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
