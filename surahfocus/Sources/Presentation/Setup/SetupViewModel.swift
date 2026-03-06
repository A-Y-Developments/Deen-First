import FamilyControls
import SwiftUI

@MainActor
final class SetupViewModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var isPickerPresented = false
    @Published var selectedAppsCount: Int = 0
    @Published var selectedCategoriesCount: Int = 0

    @Published var selectedDailyLimit: TimeLimit? = nil

    @Published var selectedPrayers: Set<String> = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let screenTimeRulesService: ScreenTimeRulesService
    private let authCenter: AuthorizationCenter

    init(
        screenTimeRulesService: ScreenTimeRulesService,
        authCenter: AuthorizationCenter = .shared
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.authCenter = authCenter
    }

    convenience init() {
        self.init(screenTimeRulesService: DIContainer.shared.screenTimeRulesService)
    }

    func openPicker() {
        isPickerPresented = true
    }

    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        selectedAppsCount = selection.applicationTokens.count
        selectedCategoriesCount = selection.categoryTokens.count
    }

    func canProceedFromSelection() -> Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    func selectLimit(_ limit: TimeLimit) {
        selectedDailyLimit = limit
    }

    func skipDailyLimit() {
        selectedDailyLimit = nil
    }

    func togglePrayer(_ prayer: String) {
        if selectedPrayers.contains(prayer) {
            selectedPrayers.remove(prayer)
        } else {
            selectedPrayers.insert(prayer)
        }
    }

    func isSelected(_ prayer: String) -> Bool {
        selectedPrayers.contains(prayer)
    }

    func saveAppSelection() {
        guard let sharedDefaults = AppGroupConstants.sharedDefaults else { return }

        // Save application tokens
        var tokenMapping: [String: Data] = [:]
        for token in selection.applicationTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                tokenMapping[key] = encoded
            }
        }
        sharedDefaults.set(tokenMapping, forKey: AppGroupConstants.tokenMappingKey)

        // Save category tokens
        var categoryMapping: [String: Data] = [:]
        for token in selection.categoryTokens {
            if let encoded = try? JSONEncoder().encode(token) {
                let key = String(token.hashValue)
                categoryMapping[key] = encoded
            }
        }
        sharedDefaults.set(categoryMapping, forKey: AppGroupConstants.categoryTokensKey)
    }

    var previewAppLimitRule: ScreenTimeRule? {
        guard let limit = selectedDailyLimit,
            !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
        else {
            return nil
        }

        return ScreenTimeRule(
            name: "Daily Limit",
            selection: selection,
            type: .timeLimit,
            limitSeconds: limit.seconds,
            daysActive: []
        )
    }

    var previewtimeLimitRules: [ScreenTimeRule] {
        selectedPrayers.compactMap { prayer in
            let range = getPrayerTimeRange(prayer)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            guard let startDate = formatter.date(from: range.start),
                let endDate = formatter.date(from: range.end)
            else {
                return nil
            }

            let startComponents = Calendar.current.dateComponents(
                [.hour, .minute], from: startDate)
            let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

            return ScreenTimeRule(
                name: "During \(getPrayerDisplayName(prayer))",
                selection: selection,
                type: .timeLimit,
                startTime: startComponents,
                endTime: endComponents,
                daysActive: []
            )
        }
    }

    var hasAnyRules: Bool {
        previewAppLimitRule != nil || !previewtimeLimitRules.isEmpty
    }

    func saveSetup() async {
        isLoading = true
        errorMessage = nil

        do {
            guard authCenter.authorizationStatus == .approved else {
                errorMessage = "Screen Time permission not granted"
                isLoading = false
                return
            }

            if let limit = selectedDailyLimit {
                let config = AppLimitConfig(
                    name: "Daily Limit",
                    timeLimit: limit,
                    daysActive: []
                )
                try await screenTimeRulesService.setAppLimitBlock(for: selection, config: config)
            }

            for prayer in selectedPrayers {
                let range = getPrayerTimeRange(prayer)

                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"

                guard let startDate = formatter.date(from: range.start),
                    let endDate = formatter.date(from: range.end)
                else { continue }

                let startComponents = Calendar.current.dateComponents(
                    [.hour, .minute], from: startDate)
                let endComponents = Calendar.current.dateComponents(
                    [.hour, .minute], from: endDate)

                let config = TimeLimitConfig(
                    name: "During \(getPrayerDisplayName(prayer))",
                    startTime: startComponents,
                    endTime: endComponents,
                    daysActive: []
                )
                try await screenTimeRulesService.setTimeLimitBlock(for: selection, config: config)
            }

            logTimeBlockSettings(
                appCount: selectedAppsCount,
                categoryCount: selectedCategoriesCount,
                dailyLimit: selectedDailyLimit,
                selectedPrayers: selectedPrayers
            )

            // Save app selection for use in Focus Session
            saveAppSelection()

            if let user = try? await DIContainer.shared.userRepository.getCurrentUser() {
                user.hasCompletedSetup = true
                try? await DIContainer.shared.userRepository.updateUser(user)
            }

            NotificationCenter.default.post(name: .didCompleteScreenTimeSetup, object: nil)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    private func getPrayerTimeRange(_ prayer: String) -> (start: String, end: String) {
        switch prayer {
        case "subuh": return ("04:30", "06:00")
        case "zuhr": return ("12:15", "13:30")
        case "asr": return ("15:45", "17:00")
        case "maghrib": return ("18:15", "19:15")
        case "isya": return ("19:30", "20:45")
        default: return ("00:00", "23:59")
        }
    }

    private func getPrayerDisplayName(_ prayer: String) -> String {
        switch prayer {
        case "subuh": return "Fajr"
        case "zuhr": return "Dhuhr"
        case "asr": return "Asr"
        case "maghrib": return "Maghrib"
        case "isya": return "Isha"
        default: return prayer
        }
    }

    private func logTimeBlockSettings(
        appCount: Int,
        categoryCount: Int,
        dailyLimit: TimeLimit?,
        selectedPrayers: Set<String>
    ) {
        print("=== TIME BLOCK SETTINGS LOG ===")

        if let limit = dailyLimit {
            print("\nType: App Limit")
            print("Name: Daily Limit")
            print(
                "App Selection: \(categoryCount) Category\(categoryCount == 1 ? "" : "es"), \(appCount) App\(appCount == 1 ? "" : "s")"
            )
            print("Time: \(limit.displayName)")
            print("Days: All Days")
        }

        for prayer in selectedPrayers {
            let range = getPrayerTimeRange(prayer)
            print("\nType: Time of Day")
            print("Name: During \(getPrayerDisplayName(prayer))")
            print(
                "App Selection: \(categoryCount) Category\(categoryCount == 1 ? "" : "es"), \(appCount) App\(appCount == 1 ? "" : "s")"
            )
            print("Time: \(range.start) - \(range.end)")
            print("Days: All Days")
        }

        print("\n==============================")
    }
}
