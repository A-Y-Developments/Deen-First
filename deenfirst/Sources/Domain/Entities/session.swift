import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var type: SessionType
    var surahNumbers: [Int]
    var reciterId: Int?
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int
    var isCompleted: Bool
    var isUnblockSession: Bool
    var unlockRuleId: UUID?

    enum SessionType: String, Codable {
        case reading
        case listening
    }

    init(
        userId: UUID,
        type: SessionType,
        surahNumbers: [Int],
        reciterId: Int? = nil,
        isUnblockSession: Bool = false,
        unlockRuleId: UUID? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.type = type
        self.surahNumbers = surahNumbers
        self.reciterId = reciterId
        self.startTime = Date()
        self.endTime = nil
        self.durationSeconds = 0
        self.isCompleted = false
        self.isUnblockSession = isUnblockSession
        self.unlockRuleId = unlockRuleId
    }

    // Helper computed property
    // Engagement counts immediately - no minimum time requirement
    var isValid: Bool {
        return true
    }
}
