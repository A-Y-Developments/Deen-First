import Foundation
import SwiftData

@Model
final class PendingRuleChange {
    @Attribute(.unique) var id: UUID
    var ruleId: UUID
    var changeType: String
    var pendingData: Data?
    var requestedAt: Date
    var appliesAt: Date
    var isCancelled: Bool
    var isApplied: Bool
    var createdAt: Date

    static let applyDelaySeconds: TimeInterval = 86_400

    init(
        ruleId: UUID,
        changeType: PendingChangeType,
        pendingData: Data? = nil,
        requestedAt: Date = Date()
    ) {
        self.id = UUID()
        self.ruleId = ruleId
        self.changeType = changeType.rawValue
        self.pendingData = pendingData
        self.requestedAt = requestedAt
        self.appliesAt = requestedAt.addingTimeInterval(Self.applyDelaySeconds)
        self.isCancelled = false
        self.isApplied = false
        self.createdAt = requestedAt
    }
}

enum PendingChangeType: String, Codable {
    case edit
    case delete
    case disable
    case disableHardMode
    case disableLockEditing
}
