import Foundation

/// Tiered unblock options shown to users who attempt to unblock a rule mid-block.
/// Canonical source of truth for tier-to-minutes and tier-to-ayah-count mappings.
/// Belongs to Domain because `ActiveSessionViewModel`, `ReciteToUnblockViewModel`,
/// and `UnblockDurationSelectionViewModel` all need to reach it without cross-presentation imports.
enum UnblockTier: String, CaseIterable {
    case tier1  // 5 min, recite 1 ayah (2 in Hard Mode)
    case tier2  // 10 min, recite 2 ayahs (3 in Hard Mode)
    case tier3  // 15 min (20 in Hard Mode), complete a Quran session

    var minutes: Int {
        switch self {
        case .tier1: return 5
        case .tier2: return 10
        case .tier3: return 15
        }
    }

    func minutes(isHardMode: Bool) -> Int {
        switch self {
        case .tier3: return isHardMode ? 20 : 15
        default: return minutes
        }
    }

    func ayahCount(isHardMode: Bool) -> Int {
        switch (self, isHardMode) {
        case (.tier1, true): return 2
        case (.tier2, true): return 3
        case (.tier1, false): return 1
        case (.tier2, false): return 2
        default: return 0
        }
    }

    static func closest(to minutes: Int) -> UnblockTier {
        switch minutes {
        case ..<8: return .tier1
        case 8..<13: return .tier2
        default: return .tier3
        }
    }
}
