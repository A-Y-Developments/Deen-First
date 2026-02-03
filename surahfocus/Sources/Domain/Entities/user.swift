//
//  user.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

@Model
class User {
    var id: String
    var authProvider: String?
    var email: String?
    var name: String?
    var createdAt: Date

    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var subscriptionExpiryDate: Date?

    var currentStreak: Int
    var longestStreak: Int
    var lastEngagementDate: Date?

    @Relationship(deleteRule: .cascade) var sessions: [Session]?
    @Relationship(deleteRule: .cascade) var blockedApps: [BlockedApp]?
    @Relationship(deleteRule: .cascade) var appTimeLimits: [AppTimeLimit]?

    init(
        id: String = UUID().uuidString,
        authProvider: String? = nil,
        email: String? = nil,
        name: String? = nil,
        createdAt: Date = Date(),
        hasCompletedOnboarding: Bool = false,
        isPremium: Bool = false,
        subscriptionExpiryDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastEngagementDate: Date? = nil
    ) {
        self.id = id
        self.authProvider = authProvider
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isPremium = isPremium
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastEngagementDate = lastEngagementDate
    }
}
