import SwiftUI
import FamilyControls

@MainActor
final class SetupViewModel: ObservableObject {
    // MARK: - Step 1: Selection
    @Published var selection = FamilyActivitySelection()
    @Published var isPickerPresented = false
    @Published var selectedAppsCount: Int = 0
    @Published var selectedCategoriesCount: Int = 0

    // MARK: - Step 2: Daily Limit
    @Published var selectedDailyLimit: TimeLimit? = nil

    // MARK: - Step 3: Downtime
    @Published var selectedPrayers: Set<String> = []

    // MARK: - Common
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let screenTimeRulesUseCase: ScreenTimeRulesUseCase
    private let authCenter: AuthorizationCenter

    // MARK: - Initialization
    init(
        screenTimeRulesUseCase: ScreenTimeRulesUseCase,
        authCenter: AuthorizationCenter = .shared
    ) {
        self.screenTimeRulesUseCase = screenTimeRulesUseCase
        self.authCenter = authCenter
    }

    convenience init() {
        self.init(screenTimeRulesUseCase: DIContainer.shared.screenTimeRulesUseCase)
    }

    // MARK: - Selection Methods
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

    // MARK: - Limit Methods
    func selectLimit(_ limit: TimeLimit) {
        selectedDailyLimit = limit
    }

    func skipDailyLimit() {
        selectedDailyLimit = nil
    }

    // MARK: - Downtime Methods
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

    // MARK: - Preview Rules for SetupSummary
    var previewAppLimitRule: ScreenTimeRule? {
        guard let limit = selectedDailyLimit,
              !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
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

    var previewTimeOfDayRules: [ScreenTimeRule] {
        selectedPrayers.compactMap { prayer in
            let range = getPrayerTimeRange(prayer)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            guard let startDate = formatter.date(from: range.start),
                  let endDate = formatter.date(from: range.end) else {
                return nil
            }

            let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
            let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

            return ScreenTimeRule(
                name: "During \(getPrayerDisplayName(prayer))",
                selection: selection,
                type: .timeOfDay,
                startTime: startComponents,
                endTime: endComponents,
                daysActive: []
            )
        }
    }

    var hasAnyRules: Bool {
        previewAppLimitRule != nil || !previewTimeOfDayRules.isEmpty
    }

    // MARK: - Completion
    func saveSetup() async {
        isLoading = true
        errorMessage = nil

        do {
            guard authCenter.authorizationStatus == .approved else {
                errorMessage = "Screen Time permission not granted"
                isLoading = false
                return
            }

            // 1. Create App Limit if daily limit selected
            if let limit = selectedDailyLimit {
                let config = TimeLimitConfig(
                    name: "Daily Limit",
                    timeLimit: limit,
                    daysActive: []
                )
                try await screenTimeRulesUseCase.setTimeLimit(for: selection, config: config)
            }

            // 2. Create Time of Day blocks for each selected prayer
            for prayer in selectedPrayers {
                let range = getPrayerTimeRange(prayer)

                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"

                guard let startDate = formatter.date(from: range.start),
                      let endDate = formatter.date(from: range.end) else {
                    continue
                }

                let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
                let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)

                let config = TimeOfDayConfig(
                    name: "During \(getPrayerDisplayName(prayer))",
                    startTime: startComponents,
                    endTime: endComponents,
                    daysActive: []
                )
                try await screenTimeRulesUseCase.setTimeOfDayBlock(for: selection, config: config)
            }

            // 3. Log settings
            logTimeBlockSettings(
                appCount: selectedAppsCount,
                categoryCount: selectedCategoriesCount,
                dailyLimit: selectedDailyLimit,
                selectedPrayers: selectedPrayers
            )

            // 4. Post notification for setup completion
            NotificationCenter.default.post(name: .didCompleteScreenTimeSetup, object: nil)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Helpers
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
            print("App Selection: \(categoryCount) Category\(categoryCount == 1 ? "" : "es"), \(appCount) App\(appCount == 1 ? "" : "s")")
            print("Time: \(limit.displayName)")
            print("Days: All Days")
        }

        for prayer in selectedPrayers {
            let range = getPrayerTimeRange(prayer)
            print("\nType: Time of Day")
            print("Name: During \(getPrayerDisplayName(prayer))")
            print("App Selection: \(categoryCount) Category\(categoryCount == 1 ? "" : "es"), \(appCount) App\(appCount == 1 ? "" : "s")")
            print("Time: \(range.start) - \(range.end)")
            print("Days: All Days")
        }

        print("\n==============================")
    }
}
