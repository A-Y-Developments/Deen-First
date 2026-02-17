import SwiftUI
import FamilyControls

@MainActor
final class BlockingTabViewModelNew: ObservableObject {
    // MARK: - Published Properties

    @Published var appLimits: [ScreenTimeRule] = []
    @Published var timeOfDayLimits: [ScreenTimeRule] = []
    @Published var allDayLimits: [ScreenTimeRule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showActivityPicker = false
    @Published var appSelection = FamilyActivitySelection()

    // MARK: - Dependencies

    private let screenTimeRulesUseCase: ScreenTimeRulesUseCase

    // MARK: - Initialization

    init(screenTimeRulesUseCase: ScreenTimeRulesUseCase = DIContainer.shared.screenTimeRulesUseCase) {
        self.screenTimeRulesUseCase = screenTimeRulesUseCase
    }

    convenience init() {
        self.init(screenTimeRulesUseCase: DIContainer.shared.screenTimeRulesUseCase)
    }

    // MARK: - Load Data

    func loadBlockedApps() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all rules from the new unified system
            appLimits = screenTimeRulesUseCase.getTimeLimitRules()
            timeOfDayLimits = screenTimeRulesUseCase.getTimeOfDayRules()
            allDayLimits = screenTimeRulesUseCase.getAllDayRules()

            // Sort by creation date
            appLimits.sort { $0.createdAt < $1.createdAt }
            timeOfDayLimits.sort { $0.createdAt < $1.createdAt }
            allDayLimits.sort { $0.createdAt < $1.createdAt }

            isLoading = false

            logTimeBlockSettings()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Delete Operations

    func deleteAppLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesUseCase.deleteTimeLimit(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTimeOfDayLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesUseCase.deleteTimeOfDay(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllDayLimit(_ limit: ScreenTimeRule) async {
        do {
            try await screenTimeRulesUseCase.deleteAllDay(id: limit.id)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    var blockedAppsCount: Int {
        appLimits.count + timeOfDayLimits.count + allDayLimits.count
    }

    var hasApps: Bool {
        !appLimits.isEmpty || !timeOfDayLimits.isEmpty || !allDayLimits.isEmpty
    }

    var hasAppLimits: Bool {
        !appLimits.isEmpty
    }

    var hasTimeOfDayLimits: Bool {
        !timeOfDayLimits.isEmpty
    }

    var hasAllDayLimits: Bool {
        !allDayLimits.isEmpty
    }

    // MARK: - Logging

    private func logTimeBlockSettings() {
        print("=== TIME BLOCK SETTINGS LOG ===")

        for limit in appLimits {
            print("\nType: App Limit")
            print("Name: \(limit.name)")
            let selection = limit.getFamilyActivitySelection()
            print("App Selection: \(selection.categoryTokens.count) Category(ies), \(selection.applicationTokens.count) App(s)")
            if let display = limit.limitDisplayName {
                print("Time: \(display)")
            }
            print("Days: \(limit.daysDisplayText)")
        }

        for limit in timeOfDayLimits {
            print("\nType: Time Limit (Downtime)")
            print("Name: \(limit.name)")
            let selection = limit.getFamilyActivitySelection()
            print("App Selection: \(selection.categoryTokens.count) Category(ies), \(selection.applicationTokens.count) App(s)")
            if let display = limit.timeRangeDisplay {
                print("Time: \(display)")
            }
            print("Days: \(limit.daysDisplayText)")
        }

        for limit in allDayLimits {
            print("\nType: All Day")
            print("Name: \(limit.name)")
            let selection = limit.getFamilyActivitySelection()
            print("App Selection: \(selection.categoryTokens.count) Category(ies), \(selection.applicationTokens.count) App(s)")
            print("Days: \(limit.daysDisplayText)")
        }

        print("\n==============================")
    }
}
