import Foundation

enum UnblockTier {
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
}

@MainActor final class UnblockDurationSelectionViewModel: ObservableObject {
    @Published var ruleName: String = ""
    @Published var isHardMode: Bool = false

    private let screenTimeRulesService: ScreenTimeRulesService

    init(screenTimeRulesService: ScreenTimeRulesService = DIContainer.shared.screenTimeRulesService) {
        self.screenTimeRulesService = screenTimeRulesService
    }

    func loadRule(ruleId: UUID) {
        guard let rule = screenTimeRulesService.getRule(id: ruleId) else { return }
        ruleName = rule.name
        isHardMode = rule.isHardMode
    }
}
