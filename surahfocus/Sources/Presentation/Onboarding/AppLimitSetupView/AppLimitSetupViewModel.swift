import SwiftUI
import ManagedSettings
import FamilyControls

@MainActor
final class AppLimitSetupViewModel: ObservableObject {
    @Published var selectedLimit: TimeLimit = .sixty  // Default 1hr
    @Published var selectedApps: [ApplicationToken] = []
    @Published var isSaving = false

    func loadApps(_ apps: [ApplicationToken]) {
        selectedApps = apps
    }

    func setLimit(_ limit: TimeLimit) {
        selectedLimit = limit
    }

    func save() {
        // Save to AppGroup UserDefaults for Shield extension access
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }

        // Save global limit in minutes
        sharedDefaults.set(selectedLimit.minutes, forKey: "globalAppLimitMinutes")

        // Save that limit is enabled
        sharedDefaults.set(true, forKey: "appLimitEnabled")
    }

    func skip() {
        // Skip means no limit - set to a very high value or disable
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else { return }
        sharedDefaults.set(false, forKey: "appLimitEnabled")
    }
}
