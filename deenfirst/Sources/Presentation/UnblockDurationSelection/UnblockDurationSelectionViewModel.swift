import Foundation

// UnblockTier enum was moved to Domain/Entities/UnblockTier.swift (DF-032 / DF-115) so the
// Session and ActiveSession ViewModels can reach it without cross-presentation imports.

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
