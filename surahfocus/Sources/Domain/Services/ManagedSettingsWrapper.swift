import Foundation
import ManagedSettings
import FamilyControls

@MainActor
final class ManagedSettingsWrapper {
    let store = ManagedSettingsStore()

    func applyShields(applicationTokens: Set<ApplicationToken>, categoryTokens: Set<ActivityCategoryToken>) {
        if !applicationTokens.isEmpty {
            store.shield.applications = applicationTokens
        }
        if !categoryTokens.isEmpty {
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(categoryTokens)
        }
    }

    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
