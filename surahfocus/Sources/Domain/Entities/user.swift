import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var appleUserId: String
    var email: String?
    var name: String?
    var hasCompletedOnboarding: Bool
    var hasCompletedSetup: Bool
    var hasCompletedAppSelection: Bool
    var hasCompletedAppLimitSetup: Bool
    var hasCompletedDowntimeSetup: Bool
    var currentStreak: Int
    var longestStreak: Int
    var createdAt: Date
    var lastActiveDate: Date?

    init(
        appleUserId: String,
        email: String? = nil,
        name: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.appleUserId = appleUserId
        self.email = email
        self.name = name
        self.hasCompletedOnboarding = false
        self.hasCompletedSetup = false
        self.hasCompletedAppSelection = false
        self.hasCompletedAppLimitSetup = false
        self.hasCompletedDowntimeSetup = false
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdAt = createdAt
        self.lastActiveDate = nil
    }
}