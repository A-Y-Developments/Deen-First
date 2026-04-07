import SwiftData
import XCTest

@testable import DeenFirst

@MainActor
final class PendingRuleChangeTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([PendingRuleChange.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func testInitializationDefaults() {
        let ruleId = UUID()
        let requestedAt = Date()
        let change = PendingRuleChange(
            ruleId: ruleId,
            changeType: .edit,
            pendingData: Data([0x01, 0x02]),
            requestedAt: requestedAt
        )

        XCTAssertNotNil(change.id)
        XCTAssertEqual(change.ruleId, ruleId)
        XCTAssertEqual(change.changeType, "edit")
        XCTAssertEqual(change.pendingData, Data([0x01, 0x02]))
        XCTAssertEqual(change.requestedAt, requestedAt)
        XCTAssertFalse(change.isCancelled)
        XCTAssertFalse(change.isApplied)
        XCTAssertEqual(change.createdAt, requestedAt)
    }

    func testAppliesAtIs24HoursAfterRequestedAt() {
        let requestedAt = Date()
        let change = PendingRuleChange(ruleId: UUID(), changeType: .delete, requestedAt: requestedAt)

        XCTAssertEqual(change.appliesAt.timeIntervalSince(requestedAt), 86_400, accuracy: 0.001)
    }

    func testAllChangeTypesPersistRawValue() {
        let cases: [(PendingChangeType, String)] = [
            (.edit, "edit"),
            (.delete, "delete"),
            (.disable, "disable"),
            (.disableHardMode, "disableHardMode"),
            (.disableLockEditing, "disableLockEditing"),
        ]
        for (type, raw) in cases {
            let change = PendingRuleChange(ruleId: UUID(), changeType: type)
            XCTAssertEqual(change.changeType, raw)
        }
    }

    func testPersistAndFetch() throws {
        let ruleId = UUID()
        let change = PendingRuleChange(ruleId: ruleId, changeType: .disableLockEditing)
        context.insert(change)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<PendingRuleChange>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.ruleId, ruleId)
        XCTAssertEqual(fetched.first?.changeType, "disableLockEditing")
        let record = try XCTUnwrap(fetched.first)
        XCTAssertEqual(record.appliesAt.timeIntervalSince(record.requestedAt), 86_400, accuracy: 0.001)
    }

    func testUpdateCancelledFlag() throws {
        let change = PendingRuleChange(ruleId: UUID(), changeType: .edit)
        context.insert(change)
        try context.save()

        change.isCancelled = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<PendingRuleChange>())
        XCTAssertTrue(fetched.first?.isCancelled ?? false)
    }

    func testUpdateAppliedFlag() throws {
        let change = PendingRuleChange(ruleId: UUID(), changeType: .edit)
        context.insert(change)
        try context.save()

        change.isApplied = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<PendingRuleChange>())
        XCTAssertTrue(fetched.first?.isApplied ?? false)
    }
}
