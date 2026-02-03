import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class UserTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([User.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testUserInitialization() {
        let user = User(
            appleUserId: "test123",
            email: "test@example.com",
            name: "Test User"
        )

        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.appleUserId, "test123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertFalse(user.isPremium)
        XCTAssertEqual(user.currentStreak, 0)
        XCTAssertEqual(user.longestStreak, 0)
        XCTAssertNil(user.lastActiveDate)
    }

    func testStreakIncrementOnFirstActivity() {
        let user = User(appleUserId: "test123")

        user.updateStreak(isActiveToday: true)

        XCTAssertEqual(user.currentStreak, 1)
        XCTAssertEqual(user.longestStreak, 1)
        XCTAssertNotNil(user.lastActiveDate)
    }

    func testStreakIncrementOnConsecutiveDays() {
        let user = User(appleUserId: "test123")

        // Day 1
        user.lastActiveDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        user.currentStreak = 1
        user.longestStreak = 1

        // Day 2
        user.updateStreak(isActiveToday: true)

        XCTAssertEqual(user.currentStreak, 2)
        XCTAssertEqual(user.longestStreak, 2)
    }

    func testStreakResetsAfterMissedDay() {
        let user = User(appleUserId: "test123")

        // Day 1
        user.lastActiveDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        user.currentStreak = 5
        user.longestStreak = 5

        // Day 3 (missed day 2)
        user.updateStreak(isActiveToday: true)

        XCTAssertEqual(user.currentStreak, 1)
        XCTAssertEqual(user.longestStreak, 5) // Longest unchanged
    }

    func testStreakUnchangedIfAlreadyActiveToday() {
        let user = User(appleUserId: "test123")
        user.currentStreak = 3
        user.lastActiveDate = Date()

        user.updateStreak(isActiveToday: true)

        XCTAssertEqual(user.currentStreak, 3) // Unchanged
    }

    func testPersistenceInSwiftData() throws {
        let user = User(appleUserId: "persist123", email: "persist@test.com")
        context.insert(user)
        try context.save()

        let fetchDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(fetchDescriptor)

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.appleUserId, "persist123")
    }
}
