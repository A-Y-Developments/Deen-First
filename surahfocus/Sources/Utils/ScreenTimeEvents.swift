import Foundation
import ManagedSettings
import DeviceActivity
import FamilyControls

// MARK: - Screen Time Event Names

public enum ScreenTimeEvents {
    static let sessionStart = DeviceActivityEvent.Name("sessionStart")
    static let sessionEnd = DeviceActivityEvent.Name("sessionEnd")
    static let limitReached = DeviceActivityEvent.Name("limitReached")
    static let shieldApplied = DeviceActivityEvent.Name("shieldApplied")
    static let shieldRemoved = DeviceActivityEvent.Name("shieldRemoved")

    // MARK: - Event Creation for App Limits

    static func createEvents(for limit: TimeLimit, selection: [AppLimitToken]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        print("📝 Creating events for limit: \(limit.displayName) (\(limit.seconds)s) for \(selection.count) apps")

        for app in selection {
            // Handle individual apps
            if let token = app.applicationToken {
                // Use app.id directly (like mindcore) - consistent between event creation and shield application
                let eventName = DeviceActivityEvent.Name("limitReached_app_\(app.id.uuidString)")
                print("  ✅ Created app event: \(eventName.rawValue) with threshold: \(limit.seconds)s")
                events[eventName] = DeviceActivityEvent(
                    applications: [token],
                    categories: [],
                    webDomains: [],
                    threshold: DateComponents(second: limit.seconds)
                )
                saveTokenMapping(uuid: app.id, token: token)
            }

            // Handle categories
            if let categoryToken = app.categoryToken {
                let eventName = DeviceActivityEvent.Name("limitReached_category_\(app.id.uuidString)")
                events[eventName] = DeviceActivityEvent(
                    applications: [],
                    categories: [categoryToken],
                    webDomains: [],
                    threshold: DateComponents(second: limit.seconds)
                )
                saveCategoryToken(uuid: app.id, token: categoryToken)
            }
        }
        return events
    }

    // MARK: - Token Persistence

    private static func saveTokenMapping(uuid: UUID, token: ApplicationToken) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }
        var dict = defaults.dictionary(forKey: AppGroupConstants.tokenMappingKey) as? [String: Data] ?? [:]
        if let data = try? JSONEncoder().encode(token) {
            dict[uuid.uuidString] = data
            defaults.set(dict, forKey: AppGroupConstants.tokenMappingKey)
            print("💾 Saved token mapping: \(uuid.uuidString) -> total: \(dict.count) tokens")
        }
    }

    private static func saveCategoryToken(uuid: UUID, token: ActivityCategoryToken) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }
        var dict = defaults.dictionary(forKey: AppGroupConstants.categoryTokensKey) as? [String: Data] ?? [:]
        if let data = try? JSONEncoder().encode(token) {
            dict[uuid.uuidString] = data
            defaults.set(dict, forKey: AppGroupConstants.categoryTokensKey)
        }
    }

    // MARK: - Event Creation for Time of Day (Downtime/Prayer Times)

    static func createTimeOfDayEvents(for selection: [AppLimitToken]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for app in selection {
            if let token = app.applicationToken {
                let eventName = DeviceActivityEvent.Name("timeOfDay_app_\(app.id.uuidString)")
                events[eventName] = DeviceActivityEvent(
                    applications: [token],
                    categories: [],
                    webDomains: [],
                    threshold: DateComponents(hour: 0, minute: 0)
                )
                saveTokenMapping(uuid: app.id, token: token)
            }

            if let categoryToken = app.categoryToken {
                let eventName = DeviceActivityEvent.Name("timeOfDay_category_\(app.id.uuidString)")
                events[eventName] = DeviceActivityEvent(
                    applications: [],
                    categories: [categoryToken],
                    webDomains: [],
                    threshold: DateComponents(hour: 0, minute: 0)
                )
                saveCategoryToken(uuid: app.id, token: categoryToken)
            }
        }
        return events
    }

    // MARK: - Event Creation for All Day Limits

    static func createAllDayEvents(for selection: [AppLimitToken]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for app in selection {
            if let token = app.applicationToken {
                let eventName = DeviceActivityEvent.Name("allDay_app_\(app.id.uuidString)")
                events[eventName] = DeviceActivityEvent(
                    applications: [token],
                    categories: [],
                    webDomains: [],
                    threshold: DateComponents(hour: 0, minute: 0)
                )
                saveTokenMapping(uuid: app.id, token: token)
            }

            if let categoryToken = app.categoryToken {
                let eventName = DeviceActivityEvent.Name("allDay_category_\(app.id.uuidString)")
                events[eventName] = DeviceActivityEvent(
                    applications: [],
                    categories: [categoryToken],
                    webDomains: [],
                    threshold: DateComponents(hour: 0, minute: 0)
                )
                saveCategoryToken(uuid: app.id, token: categoryToken)
            }
        }
        return events
    }
}

// MARK: - App Limit Token Model

public struct AppLimitToken {
    public let id: UUID
    public let applicationToken: ApplicationToken?
    public let categoryToken: ActivityCategoryToken?

    public init(id: UUID = UUID(), applicationToken: ApplicationToken? = nil, categoryToken: ActivityCategoryToken? = nil) {
        self.id = id
        self.applicationToken = applicationToken
        self.categoryToken = categoryToken
    }
}

// MARK: - Event Metadata Keys

extension ScreenTimeEvents {
    enum MetadataKey: String {
        case surahId = "surahId"
        case sessionId = "sessionId"
        case timeLimit = "timeLimit"
        case timestamp = "timestamp"
    }
}

// MARK: - Activity Names

public enum ScreenTimeActivity {
    public static let dailyMonitoring = DeviceActivityName("dailyMonitoring")
    public static let quranSession = DeviceActivityName("quranSession")

    public static func dailyMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("daily_\(ruleId.uuidString)")
    }

    public static func timeOfDayMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("timeOfDay_\(ruleId.uuidString)")
    }

    public static func allDayMonitoring(for ruleId: UUID) -> DeviceActivityName {
        DeviceActivityName("allDay_\(ruleId.uuidString)")
    }
}
