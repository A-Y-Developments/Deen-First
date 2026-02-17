import Foundation
import SwiftData

@Model
final class TimeLimitSettings {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var name: String
    var appTokens: [Data]
    var startTime: String
    var endTime: String
    var activeDays: [Int]
    var isAllDay: Bool
    var prayerTimes: [String]
    var createdAt: Date
    var isActive: Bool

    init(
        userId: UUID,
        name: String,
        appTokens: [Data],
        startTime: String,
        endTime: String,
        activeDays: [Int],
        isAllDay: Bool,
        prayerTimes: [String]
    ) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.appTokens = appTokens
        self.startTime = startTime
        self.endTime = endTime
        self.activeDays = activeDays
        self.isAllDay = isAllDay
        self.prayerTimes = prayerTimes
        self.createdAt = Date()
        self.isActive = true
    }
}
