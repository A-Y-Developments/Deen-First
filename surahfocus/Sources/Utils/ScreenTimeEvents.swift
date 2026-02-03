import Foundation
import DeviceActivity

// MARK: - Screen Time Event Names

enum ScreenTimeEvents {
    static let sessionStart = DeviceActivityEvent.Name("sessionStart")
    static let sessionEnd = DeviceActivityEvent.Name("sessionEnd")
    static let limitReached = DeviceActivityEvent.Name("limitReached")
    static let shieldApplied = DeviceActivityEvent.Name("shieldApplied")
    static let shieldRemoved = DeviceActivityEvent.Name("shieldRemoved")
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

enum ScreenTimeActivity {
    static let dailyMonitoring = DeviceActivityName("dailyMonitoring")
    static let quranSession = DeviceActivityName("quranSession")
}
