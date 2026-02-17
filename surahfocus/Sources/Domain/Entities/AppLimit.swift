import Foundation
import SwiftData

@Model
final class AppLimit {
    @Attribute(.unique) var id: UUID
    var name: String
    var appTokens: [Data]
    var dailyLimitMinutes: Int
    var activeDays: [Int]
    var isAllDay: Bool
    var createdAt: Date
    var isActive: Bool

    init(
        name: String,
        appTokens: [Data],
        dailyLimitMinutes: Int,
        activeDays: [Int],
        isAllDay: Bool
    ) {
        self.id = UUID()
        self.name = name
        self.appTokens = appTokens
        self.dailyLimitMinutes = dailyLimitMinutes
        self.activeDays = activeDays
        self.isAllDay = isAllDay
        self.createdAt = Date()
        self.isActive = true
    }
}
