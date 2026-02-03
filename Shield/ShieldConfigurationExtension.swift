import FamilyControls
import ManagedSettings
import ShieldConfiguration
import SwiftUI

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Custom UI shown when apps are blocked
        let message = getShieldMessage()

        return ShieldConfiguration(
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Surah Focus",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: message,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0")
        )
    }

    override func configuration(shielding applicationCategory: ApplicationCategory) -> ShieldConfiguration {
        // Custom UI shown when app categories are blocked
        let message = getShieldMessage()

        return ShieldConfiguration(
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Surah Focus",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: message,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0")
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Custom UI shown when web domains are blocked
        let message = getShieldMessage()

        return ShieldConfiguration(
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Surah Focus",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: message,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0")
        )
    }

    // MARK: - Private Helpers

    private func getShieldMessage() -> String {
        guard let sharedDefaults = sharedDefaults else {
            return "Time to focus on what matters 🌙"
        }

        // Check if there's an active Quran session
        let hasActiveSession = sharedDefaults.bool(forKey: "activeSession")

        if hasActiveSession,
           let surahId = sharedDefaults.object(forKey: "activeSurahId") as? Int {
            return "Quran session active - Time to read Surah \(surahId) 🌙"
        }

        return "Time to focus on what matters 🌙"
    }
}

// UIColor extension for hex support
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
