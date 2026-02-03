import Foundation
import SwiftData

@Model
final class BlockedApp {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var appTokenData: Data
    var appName: String
    var bundleIdentifier: String
    var dailyLimitMinutes: Int
    var isActive: Bool
    var createdAt: Date

    init(
        userId: UUID,
        appTokenData: Data,
        appName: String,
        bundleIdentifier: String,
        dailyLimitMinutes: Int
    ) {
        self.id = UUID()
        self.userId = userId
        self.appTokenData = appTokenData
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.dailyLimitMinutes = dailyLimitMinutes
        self.isActive = true
        self.createdAt = Date()
    }
}
