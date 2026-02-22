import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.aydev.surahfocus"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static let tokenMappingKey = "tokenMapping"
    static let categoryTokensKey = "categoryTokens"
    static let selectedAppsKey = "selectedApps"
    static let ruleTokensKey = "ruleTokens"
}
