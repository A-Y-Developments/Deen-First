import FamilyControls
import SwiftUI

@MainActor
final class BlockingTabViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var appLimits: [ScreenTimeRule] = []
    @Published var timeLimits: [ScreenTimeRule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService

    // MARK: - Init

    init(screenTimeRulesService: ScreenTimeRulesService) {
        self.screenTimeRulesService = screenTimeRulesService
    }

    convenience init() {
        self.init(screenTimeRulesService: DIContainer.shared.screenTimeRulesService)
    }

    // MARK: - Load Data

    func loadBlockedApps() async {
        isLoading = true
        errorMessage = nil

        appLimits = screenTimeRulesService.getAppLimitRules()
        timeLimits = screenTimeRulesService.getTimeLimitRules()

        appLimits.sort { $0.createdAt < $1.createdAt }
        timeLimits.sort { $0.createdAt < $1.createdAt }

        isLoading = false
    }

    // MARK: - Delete Operations

    func deleteAppLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesService.deleteAppLimit(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTimeLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesService.deleteTimeLimit(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    var hasApps: Bool {
        !appLimits.isEmpty || !timeLimits.isEmpty
    }
}
