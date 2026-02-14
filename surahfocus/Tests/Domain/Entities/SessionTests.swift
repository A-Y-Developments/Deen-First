import XCTest
import SwiftData
@testable import SurahFocus

@MainActor
final class SessionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([Session.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testSessionInitialization() {
        let userId = UUID()
        let session = Session(
            userId: userId,
            type: .listening,
            surahNumbers: [1, 2, 3],
            reciterId: 7
        )

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.userId, userId)
        XCTAssertEqual(session.type, .listening)
        XCTAssertEqual(session.surahNumbers, [1, 2, 3])
        XCTAssertEqual(session.reciterId, 7)
        XCTAssertEqual(session.durationSeconds, 0)
        XCTAssertFalse(session.isCompleted)
    }

    func testSessionValidityUnder2Minutes() {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1])
        session.durationSeconds = 119

        // Engagement counts immediately - no minimum time requirement
        XCTAssertTrue(session.isValid)
    }

    func testSessionValidityAtExactly2Minutes() {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1])
        session.durationSeconds = 120

        // Engagement counts immediately - no minimum time requirement
        XCTAssertTrue(session.isValid)
    }

    func testSessionValidityOver2Minutes() {
        let session = Session(userId: UUID(), type: .listening, surahNumbers: [1, 2])
        session.durationSeconds = 300

        XCTAssertTrue(session.isValid)
    }

    func testReadingSessionType() {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1])

        XCTAssertEqual(session.type, .reading)
        XCTAssertNil(session.reciterId)
    }

    func testListeningSessionType() {
        let session = Session(userId: UUID(), type: .listening, surahNumbers: [1], reciterId: 7)

        XCTAssertEqual(session.type, .listening)
        XCTAssertEqual(session.reciterId, 7)
    }

    func testPersistenceInSwiftData() throws {
        let session = Session(userId: UUID(), type: .reading, surahNumbers: [1, 2])
        context.insert(session)
        try context.save()

        let fetchDescriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(fetchDescriptor)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.surahNumbers, [1, 2])
    }
}
