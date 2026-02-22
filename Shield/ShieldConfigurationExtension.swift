import ManagedSettings
import ManagedSettingsUI
import UIKit

// MARK: - Shield Configuration Extension
// Target: Shield
// Replaces your existing ShieldConfigurationExtension.swift

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.aydev.surahfocus")
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    // MARK: - Shared Configuration

    private func makeShieldConfiguration() -> ShieldConfiguration {
        let subtitle = getShieldMessage()

        return ShieldConfiguration(
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Deen First",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0"),
            // ← NEW: secondary button triggers ShieldActionExtension
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "🎙️ Recite to Unblock",
                color: UIColor(hex: "#5C64D0")
            )
        )
    }

    // MARK: - Message

    private func getShieldMessage() -> String {
        guard let sharedDefaults = sharedDefaults else {
            return "Time to focus on what matters 🌙"
        }

        let hasActiveSession = sharedDefaults.bool(forKey: "activeSession")
        if hasActiveSession,
            let surahId = sharedDefaults.object(forKey: "activeSurahId") as? Int
        {
            return "Quran session active - Time to read Surah \(surahId) 🌙"
        }

        return "Time to focus on what matters 🌙"
    }
}

// MARK: - UIColor Hex Extension (keep your existing one or use this)

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(Double(r) / 255),
            green: CGFloat(Double(g) / 255),
            blue: CGFloat(Double(b) / 255),
            alpha: CGFloat(Double(a) / 255)
        )
    }
}