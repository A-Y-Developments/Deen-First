import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
final class TimeOfDayConfigViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
    @Published var selectedCategories: Set<Data> = []
    @Published var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var endTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @Published var activeDays: Set<Int> = []
    @Published var isAllDay: Bool = false
    @Published var selectedPrayers: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showAppPicker: Bool = false
    @Published var showTimePicker: TimePickerType?
    @Published var appSelection = FamilyActivitySelection()
    @Published var hasSetupCompleted: Bool = false

    // MARK: - Time Picker Type

    enum TimePickerType: String, Identifiable {
        case start
        case end

        var id: String { rawValue }
    }

    // MARK: - Edit Mode

    private(set) var editingRuleId: UUID?

    // MARK: - Dependencies

    private let screenTimeRulesUseCase: ScreenTimeRulesUseCase
    private let authCenter: AuthorizationCenter

    // MARK: - Constants

    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    let availablePrayers = ["subuh", "zuhr", "asr", "maghrib", "isya"]

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

        // Load time range
        if let startComponents = rule.getStartTimeComponents(),
           let startDate = Calendar.current.date(from: startComponents) {
            startTime = startDate
        }

        if let endComponents = rule.getEndTimeComponents(),
           let endDate = Calendar.current.date(from: endComponents) {
            endTime = endDate
        }

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

    // MARK: - Prayer Time Management

    func togglePrayer(_ prayer: String) {
        if selectedPrayers.contains(prayer) {
            selectedPrayers.remove(prayer)
        } else {
            selectedPrayers.insert(prayer)
        }

        // Update time range based on prayer selection
        let range = getPrayerTimeRange(prayer)
        updateTimeRange(from: range)
    }

    func getPrayerTimeRange(_ prayer: String) -> (start: String, end: String) {
        switch prayer {
        case "subuh": return ("04:30", "06:00")
        case "zuhr": return ("12:15", "13:30")
        case "asr": return ("15:45", "17:00")
        case "maghrib": return ("18:15", "19:15")
        case "isya": return ("19:30", "20:45")
        default: return ("00:00", "23:59")
        }
    }

    private func updateTimeRange(from range: (start: String, end: String)) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        if let startDate = formatter.date(from: range.start) {
            startTime = startDate
        }

        if let endDate = formatter.date(from: range.end) {
            endTime = endDate
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

    // MARK: - Time Range Validation

    func validateTimeRange() -> Bool {
        return endTime > startTime
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

            // Validate time range
            guard validateTimeRange() else {
                errorMessage = "End time must be later than start time"
                isLoading = false
                return
            }

            // Build DateComponents
            let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
            let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)

            // Build days active set
            let daysActive: Set<String>
            if isAllDay || activeDays.isEmpty {
                daysActive = [] // Empty means all days
            } else {
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                daysActive = Set(activeDays.compactMap { dayNames[$0] })
            }

            // Create config
            let config = TimeOfDayConfig(
                id: editingRuleId,
                name: settingsName.isEmpty ? "Time Limit" : settingsName,
                startTime: startComponents,
                endTime: endComponents,
                daysActive: daysActive
            )

            // Save using use case
            if editingRuleId != nil {
                // Delete existing rule first
                try? await screenTimeRulesUseCase.deleteTimeOfDay(id: editingRuleId!)
            }

            try await screenTimeRulesUseCase.setTimeOfDayBlock(for: selection, config: config)

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

    var startTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var endTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endTime)
    }

    var timeRangeText: String {
        return "\(startTimeText) - \(endTimeText)"
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

    var prayersText: String {
        if selectedPrayers.isEmpty { return "None" }

        let prayerNames: [String: String] = [
            "subuh": "Fajr",
            "zuhr": "Dhuhr",
            "asr": "Asr",
            "maghrib": "Maghrib",
            "isya": "Isha"
        ]

        return selectedPrayers
            .sorted()
            .map { prayerNames[$0] ?? $0 }
            .joined(separator: "/")
    }
}
