import Foundation

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

@MainActor final class UnblockDurationSelectionViewModel: ObservableObject {
    @Published var ruleName: String = ""
    @Published var isHardMode: Bool = false
    @Published private(set) var usedTiers: Set<UnblockTier> = []

    private let screenTimeRulesService: ScreenTimeRulesService
    private let sharedDefaults: UserDefaults?
    private(set) var ruleId: UUID?

    init(
        screenTimeRulesService: ScreenTimeRulesService = MainActor.assumeIsolated { DIContainer.shared.screenTimeRulesService },
        sharedDefaults: UserDefaults? = AppGroupConstants.sharedDefaults
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.sharedDefaults = sharedDefaults
    }

    func loadRule(ruleId: UUID) {
        guard let rule = screenTimeRulesService.getRule(id: ruleId) else { return }
        self.ruleId = ruleId
        ruleName = rule.name
        isHardMode = rule.isHardMode
        usedTiers = UsedTiersStore.usedTiers(ruleId: ruleId, defaults: sharedDefaults)
    }

    /// DF-022 / DF-023: a tier is available when the 3-tier cap isn't reached,
    /// the tier hasn't already been used, and the previous tier has been completed.
    func isAvailable(_ tier: UnblockTier) -> Bool {
        if usedTiers.count >= 3 { return false }
        if usedTiers.contains(tier) { return false }
        switch tier {
        case .tier1: return true
        case .tier2: return usedTiers.contains(.tier1)
        case .tier3: return usedTiers.contains(.tier2)
        }
    }
}
