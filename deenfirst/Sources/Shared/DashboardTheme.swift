import SwiftUI

/// Brand palette + shared styling tokens for the Dashboard.
///
/// Lives in `Shared/` so both the main app and the `DeenFirstActivityReport`
/// extension can use it. The extension target does **not** pull `Utils/` (where
/// `Color(hex:)` / `Color.primary900` live) or the asset catalog, so colors here
/// are defined with `Color(.sRGB,…)` literals — no asset-catalog dependency.
///
/// Hex equivalents are noted inline so these stay visually identical to the
/// asset-catalog colors used elsewhere (`Primary900` `#092621`,
/// `Secondary200` `#AEF29B`).
enum DashboardTheme {
    // MARK: - Surfaces

    /// Card fill (#092621, matches `Color.primary900`) + border, for *extension-side*
    /// card chrome. Normally the card is drawn by the main app (`DashboardDetailView`)
    /// using the asset-catalog color; these are the fallback if the report host
    /// composites opaque and each section must paint its own card instead.
    static let ink = Color(.sRGB, red: 0.035, green: 0.149, blue: 0.129, opacity: 1)
    static let cardStroke = Color.white.opacity(0.06)
    /// Filled track behind progress bars / rings.
    static let track = Color.white.opacity(0.12)
    /// Background for stat tiles.
    static let tileFill = Color.white.opacity(0.06)

    // MARK: - Accent + text

    /// Primary accent — matches `Color.secondary200` (#AEF29B).
    static let accent = Color(.sRGB, red: 0.682, green: 0.949, blue: 0.608, opacity: 1)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    /// Muted bar fill for the "lesser" side of a comparison (e.g. screen time).
    static let mutedBar = Color.white.opacity(0.28)

    // MARK: - Score → color (single source of truth)

    /// Brand-tuned 5-band color for a Deen Score. Keeps low→high meaning but on
    /// on-brand hues (warm gold → lime → green) instead of harsh system colors.
    ///
    /// This is the ONLY place this mapping lives — both the Deen Score ring
    /// (`DeenScoreSectionView`) and the weekly-trend bars
    /// (`WeeklyTrendSectionView`) call it, resolving the prior drift hazard where
    /// the mapping was duplicated.
    static func ringColor(for score: Int) -> Color {
        switch score {
        case 80...: return Color(.sRGB, red: 0.600, green: 0.835, blue: 0.533, opacity: 1) // #99D588 green
        case 60..<80: return accent                                                         // #AEF29B lime
        case 40..<60: return Color(.sRGB, red: 0.898, green: 0.780, blue: 0.420, opacity: 1) // #E5C76B gold
        case 20..<40: return Color(.sRGB, red: 0.851, green: 0.643, blue: 0.255, opacity: 1) // #D9A441 amber
        default: return Color(.sRGB, red: 0.780, green: 0.420, blue: 0.353, opacity: 1)      // #C76B5A clay
        }
    }
}
