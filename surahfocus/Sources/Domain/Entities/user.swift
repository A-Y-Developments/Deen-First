import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var appleUserId: String
    var email: String?
    var name: String?
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var subscriptionExpiryDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var createdAt: Date
    var lastActiveDate: Date?

    init(
        appleUserId: String,
        email: String? = nil,
        name: String? = nil
    ) {
        self.id = UUID()
        self.appleUserId = appleUserId
        self.email = email
        self.name = name
        self.hasCompletedOnboarding = false
        self.isPremium = false
        self.subscriptionExpiryDate = nil
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdAt = Date()
        self.lastActiveDate = nil
    }

    // Helper methods
    func updateStreak(isActiveToday: Bool) {
        if isActiveToday {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            if let lastActive = lastActiveDate {
                let lastActiveDay = calendar.startOfDay(for: lastActive)
                let daysDiff = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

                if daysDiff == 0 {
                    // Already active today
                    return
                } else if daysDiff == 1 {
                    // Consecutive day
                    currentStreak += 1
                    if currentStreak > longestStreak {
                        longestStreak = currentStreak
                    }
                } else {
                    // Streak broken
                    currentStreak = 1
                }
            } else {
                // First activity
                currentStreak = 1
                longestStreak = 1
            }

            lastActiveDate = Date()
        }
    }
}
