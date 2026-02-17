import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
final class AllDayConfigViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
    @Published var selectedCategories: Set<Data> = []
    @Published var activeDays: Set<Int> = []
    @Published var isAllDay: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showAppPicker: Bool = false
    @Published var appSelection = FamilyActivitySelection()
    @Published var hasSetupCompleted: Bool = false

    // MARK: - Edit Mode

    private(set) var editingRuleId: UUID?

    // MARK: - Dependencies

    private let screenTimeRulesUseCase: ScreenTimeRulesUseCase
    private let authCenter: AuthorizationCenter

    // MARK: - Constants

    private let days = ["S", "M", "T", "W", "T", "F", "S"]

    // MARK: - Initialization

    init(
        screenTimeRulesUseCase: ScreenTimeRulesUseCase = DIContainer.shared.screenTimeRulesUseCase,
        authCenter: AuthorizationCenter = .shared
    ) {
        self.screenTimeRulesUseCase = screenTimeRulesUseCase
        self.authCenter = authCenter
    }

    // MARK: - Setup for Edit Mode

    func setupForEdit(rule: ScreenTimeRule) async {
        isLoading = true
        errorMessage = nil

        editingRuleId = rule.id
        settingsName = rule.name

        // Load selection
        let selection = rule.getFamilyActivitySelection()
        appSelection = selection

        // Encode tokens for storage
        selectedApps = Set(selection.applicationTokens.compactMap {
            try? JSONEncoder().encode($0)
        })
        selectedCategories = Set(selection.categoryTokens.compactMap {
            try? JSONEncoder().encode($0)
        })

        // Load days
        if let daysActive = rule.daysActive {
            let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            activeDays = Set(daysActive.compactMap { dayName in
                dayNames.firstIndex(of: dayName)
            })
            isAllDay = activeDays.count == 7
        }

        isLoading = false
    }

    // MARK: - Days Management

    func toggleDay(_ day: Int) {
        if activeDays.contains(day) {
            activeDays.remove(day)
        } else {
            activeDays.insert(day)
        }
        isAllDay = activeDays.count == 7
    }

    func toggleAllDay() {
        isAllDay.toggle()
        if isAllDay {
            activeDays = Set(0...6)
        } else {
            activeDays.removeAll()
        }
    }

    // MARK: - App Selection

    func addMoreApps() {
        showAppPicker = true
    }

    func handleAppPickerSelection(_ selection: FamilyActivitySelection) async {
        appSelection = selection

        // Encode tokens for storage
        selectedApps = Set(selection.applicationTokens.compactMap {
            try? JSONEncoder().encode($0)
        })
        selectedCategories = Set(selection.categoryTokens.compactMap {
            try? JSONEncoder().encode($0)
        })
    }

    // MARK: - Save Settings

    func saveSettings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Check authorization
            guard authCenter.authorizationStatus == .approved else {
                errorMessage = "Screen Time permission not granted"
                isLoading = false
                return
            }

            // Build FamilyActivitySelection
            var selection = FamilyActivitySelection()

            // Decode and add application tokens
            let applicationTokens = selectedApps.compactMap { data -> ApplicationToken? in
                try? JSONDecoder().decode(ApplicationToken.self, from: data)
            }
            selection.applicationTokens = Set(applicationTokens)

            // Decode and add category tokens
            let categoryTokens = selectedCategories.compactMap { data -> ActivityCategoryToken? in
                try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
            }
            selection.categoryTokens = Set(categoryTokens)

            // Validate selection
            guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
                errorMessage = "Please select at least one app or category"
                isLoading = false
                return
            }

            // Validate days
            let hasSelectedDays = !activeDays.isEmpty || isAllDay
            guard hasSelectedDays else {
                errorMessage = "Please select at least one day"
                isLoading = false
                return
            }

            // Build days active set
            let daysActive: Set<String>
            if isAllDay || activeDays.isEmpty {
                daysActive = [] // Empty means all days
            } else {
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                daysActive = Set(activeDays.compactMap { dayNames[$0] })
            }

            // Create config
            let config = AllDayConfig(
                id: editingRuleId,
                name: settingsName.isEmpty ? "All Day" : settingsName,
                daysActive: daysActive
            )

            // Save using use case
            if editingRuleId != nil {
                // Delete existing rule first
                try? await screenTimeRulesUseCase.deleteAllDay(id: editingRuleId!)
            }

            try await screenTimeRulesUseCase.setAllDayBlock(for: selection, config: config)

            hasSetupCompleted = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Computed Properties

    var appsCount: Int {
        selectedApps.count + selectedCategories.count
    }

    var daysText: String {
        if isAllDay { return "Every day" }
        if activeDays.isEmpty { return "No days selected" }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = Array(activeDays).sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }

    var selectionText: String {
        let apps = selectedApps.count
        let categories = selectedCategories.count

        if apps == 0 && categories == 0 {
            return "Select Apps"
        } else if apps > 0 && categories > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s"), \(categories) categor\(categories == 1 ? "y" : "ies")"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s")"
        } else {
            return "\(categories) categor\(categories == 1 ? "y" : "ies")"
        }
    }
}
