import SwiftUI
import FamilyControls

@MainActor
final class AppSelectionViewModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var isPresented = false
    @Published var selectedAppsCount: Int = 0

    // Store time limits by token hash value (String)
    private var timeLimits: [String: TimeLimit] = [:]

    func openPicker() {
        isPresented = true
    }

    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        selectedAppsCount = selection.applicationTokens.count + selection.categoryTokens.count

        // Initialize time limits for new apps
        for token in selection.applicationTokens {
            let key = tokenHash(from: token)
            if timeLimits[key] == nil {
                timeLimits[key] = .sixty
            }
        }

        // Remove time limits for deselected apps
        let currentKeys = Set(selection.applicationTokens.map { tokenHash(from: $0) })
        timeLimits = timeLimits.filter { currentKeys.contains($0.key) }

        saveSelection()
    }

    func setTimeLimit(_ limit: TimeLimit, tokenHash: String) {
        timeLimits[tokenHash] = limit
        saveSelection()
    }

    func getTimeLimit(tokenHash: String) -> TimeLimit {
        timeLimits[tokenHash] ?? .sixty
    }

    // Helper to get token hash as String
    func tokenHash(from token: AnyHashable) -> String {
        String(token.hashValue)
    }

    private func saveSelection() {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }

        // Save application tokens
        var tokenMapping: [String: Data] = [:]
        for token in selection.applicationTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                tokenMapping[tokenHash(from: token)] = encoded
            }
        }
        sharedDefaults.set(tokenMapping, forKey: AppGroupConstants.tokenMappingKey)

        // Save category tokens
        var categoryMapping: [String: Data] = [:]
        for token in selection.categoryTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                categoryMapping[tokenHash(from: token)] = encoded
            }
        }
        sharedDefaults.set(categoryMapping, forKey: AppGroupConstants.categoryTokensKey)

        // Save time limits separately
        let limitsDict = timeLimits.mapValues { $0.rawValue }
        sharedDefaults.set(limitsDict, forKey: "appTimeLimits")
    }

    func loadSavedSelection() {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }

        // Load time limits
        if let limitsDict = sharedDefaults.dictionary(forKey: "appTimeLimits") as? [String: Int] {
            timeLimits = limitsDict.compactMapValues { TimeLimit(rawValue: $0) }
        }

        selectedAppsCount = selection.applicationTokens.count + selection.categoryTokens.count
    }
}
