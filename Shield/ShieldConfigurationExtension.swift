import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Rotated Quranic Subtitles
    // Themes: remembrance of Allah, use of time, prayer, dunya vs akhirah, patience, Quran.
    // Rotate by minute — stable within the minute, fresh on each new visit.

    private let subtitles: [String] = [

        // ── Remembrance of Allah ───────────────────────────────────────────────
        "Verily, in the remembrance of Allah do hearts find rest. — Ar-Ra'd 13:28",

        "Remember Me and I will remember you. Be grateful and do not deny Me. — Al-Baqarah 2:152",

        "Remember your Lord much, and exalt Him morning and evening. — Al-Imran 3:41",

        "And remind, for reminders benefit the believers. — Adh-Dhariyat 51:55",

        // ── Prayer ─────────────────────────────────────────────────────────────
        "Establish prayer. Indeed, prayer prohibits immorality and wrongdoing. — Al-Ankabut 29:45",

        "Seek help through patience and prayer. It is hard, except for the humble. — Al-Baqarah 2:45",

        "Maintain your prayers and stand before Allah in devotion. — Al-Baqarah 2:238",

        "Indeed, prayer is an obligation on the believers at set times. — An-Nisa 4:103",

        // ── Time & Its Value ───────────────────────────────────────────────────
        "By time — indeed, mankind is in loss, except those who believe and do good. — Al-Asr 103:1-3",

        "Did We not give you a long enough life for whoever wanted to remember to do so? — Fatir 35:37",

        // ── Dunya vs Akhirah ───────────────────────────────────────────────────
        "You prefer the life of this world, but the Hereafter is better and more lasting. — Al-A'la 87:16-17",

        "The life of this world is nothing but the enjoyment of delusion. — Al-Imran 3:185",

        "O believers! Do not let your wealth or children divert you from the remembrance of Allah. — Al-Munafiqun 63:9",

        "Know that the life of this world is but play and amusement. — Al-Hadid 57:20",

        // ── Patience & Steadfastness ───────────────────────────────────────────
        "Indeed, Allah is with the patient. — Al-Baqarah 2:153",

        "Give good news to the patient — those who say: Indeed, to Allah we belong and to Him we return. — Al-Baqarah 2:155-156",

        // ── The Quran as Guidance ──────────────────────────────────────────────
        "Indeed, this Quran guides to that which is most suitable. — Al-Isra 17:9",

        "We send down the Quran as a healing and mercy for the believers. — Al-Isra 17:82",

        // ── Tawbah & Returning to Allah ────────────────────────────────────────
        "Turn to Allah in repentance, all of you, O believers, so that you may succeed. — An-Nur 24:31",

        "Say: O My servants who have wronged themselves — never despair of Allah's mercy. — Az-Zumar 39:53",
    ]

    // MARK: - Shield Configurations

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

    // MARK: - Build Configuration

    private func makeShieldConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            icon: UIImage(named: "app-logo"),
            title: ShieldConfiguration.Label(
                text: "Blocked by Deen First",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: currentSubtitle(),
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#488D66")
            // Secondary button removed — recite to unblock is triggered from BlockingTabView
        )
    }

    // MARK: - Subtitle Rotation

    /// Returns a random ayah each time the shield appears.
    /// The shield extension is re-invoked on every block, so this always picks fresh.
    private func currentSubtitle() -> String {
        let ayah = subtitles[Int.random(in: 0..<subtitles.count)]
        let hint = "\n\nNeed a break? Open Deen First → Blocks tab\nand tap Unblock on the rule to get 5 or 15 min."
        return ayah + hint
    }
}

// MARK: - UIColor Hex

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