import Foundation

enum UnblockTier {
    case tier1  // 5 min, recite 1 ayah
    case tier2  // 10 min, recite 2 ayahs
    case tier3  // 15 min, complete a Quran session

    var minutes: Int {
        switch self {
        case .tier1: return 5
        case .tier2: return 10
        case .tier3: return 15
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
