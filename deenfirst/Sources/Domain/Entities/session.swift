import Foundation
import SwiftData

// MARK: - Purpose

/// Why this session was started. Orthogonal to `SessionModality`.
enum SessionType: Codable, Hashable {
    case normal
    /// Tier 3 Recite-to-Unblock session. `ruleId` is the rule being unblocked;
    /// nil when the session was triggered from the Shield (no specific rule context).
    case unblock(ruleId: UUID?)

    var isUnblock: Bool {
        if case .unblock = self { return true }
        return false
    }

    var unblockRuleId: UUID? {
        if case .unblock(let ruleId) = self { return ruleId }
        return nil
    }
}

// MARK: - Entity

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    @Attribute(originalName: "type") var modality: SessionModality
    var surahNumbers: [Int]
    var reciterId: Int?
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int
    var isCompleted: Bool

    // Legacy storage — do NOT read/write directly from new call sites.
    // Bridged by `type` to keep migration risk zero while callers move to the enum.
    var isUnblockSession: Bool
    var unlockRuleId: UUID?

    /// Purpose of this session. All new code should read/write this instead of
    /// the legacy `isUnblockSession` / `unlockRuleId` fields.
    var type: SessionType {
        get {
            isUnblockSession ? .unblock(ruleId: unlockRuleId) : .normal
        }
        set {
            switch newValue {
            case .normal:
                isUnblockSession = false
                unlockRuleId = nil
            case .unblock(let ruleId):
                isUnblockSession = true
                unlockRuleId = ruleId
            }
        }
    }

    /// Reading vs listening. Orthogonal to `type`.
    enum SessionModality: String, Codable {
        case reading
        case listening
    }

    init(
        userId: UUID,
        modality: SessionModality,
        surahNumbers: [Int],
        reciterId: Int? = nil,
        type: SessionType = .normal
    ) {
        self.id = UUID()
        self.userId = userId
        self.modality = modality
        self.surahNumbers = surahNumbers
        self.reciterId = reciterId
        self.startTime = Date()
        self.endTime = nil
        self.durationSeconds = 0
        self.isCompleted = false

        switch type {
        case .normal:
            self.isUnblockSession = false
            self.unlockRuleId = nil
        case .unblock(let ruleId):
            self.isUnblockSession = true
            self.unlockRuleId = ruleId
        }
    }

    // Engagement counts immediately - no minimum time requirement.
    var isValid: Bool { true }
}
