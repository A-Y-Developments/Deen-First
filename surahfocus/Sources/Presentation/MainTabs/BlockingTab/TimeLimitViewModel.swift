import FamilyControls
import ManagedSettings
import SwiftUI

@MainActor
final class TimeLimitViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
    @Published var selectedCategories: Set<Data> = []
    @Published var startTime: Date =
        Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var endTime: Date =
        Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @Published var activeDays: Set<Int> = Set(0...6)
    @Published var isAllDay: Bool = true
    @Published var selectedPrayers: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showAppPicker: Bool = false
    @Published var appSelection = FamilyActivitySelection()
    @Published var hasSetupCompleted: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var expandedPicker: PickerType? = nil

    enum PickerType { case start, end }

    // MARK: - Edit Mode

    var isEditMode: Bool { editingRuleId != nil }
    private(set) var editingRuleId: UUID?

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService
    private let authCenter: AuthorizationCenter

    // MARK: - Init

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

    // MARK: - Computed Properties

    var appsCount: Int { selectedApps.count + selectedCategories.count }

    var appsCountText: String {
        let apps = selectedApps.count
        let categories = selectedCategories.count

        if apps > 0 && categories > 0 {
            return
                "\(categories) categor\(categories == 1 ? "y" : "ies") and \(apps) app\(apps == 1 ? "" : "s") selected"
        } else if categories > 0 {
            return "\(categories) categor\(categories == 1 ? "y" : "ies") selected"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s") selected"
        } else {
            return "Select apps"
        }
    }

    var isFormValid: Bool {
        !settingsName.trimmingCharacters(in: .whitespaces).isEmpty
            && appsCount > 0
            && endTime > startTime
            && !activeDays.isEmpty
    }

    var startTimeText: String { formattedTime(startTime) }
    var endTimeText: String { formattedTime(endTime) }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Setup for Edit

    func setupForEdit(rule: ScreenTimeRule) async {
        isLoading = true
        editingRuleId = rule.id
        settingsName = rule.name

        let selection = rule.getFamilyActivitySelection()
        appSelection = selection
        selectedApps = Set(selection.applicationTokens.compactMap { try? JSONEncoder().encode($0) })
        selectedCategories = Set(
            selection.categoryTokens.compactMap { try? JSONEncoder().encode($0) })

        if let startComponents = rule.getStartTimeComponents(),
            let date = Calendar.current.date(from: startComponents)
        {
            startTime = date
        }
        if let endComponents = rule.getEndTimeComponents(),
            let date = Calendar.current.date(from: endComponents)
        {
            endTime = date
        }

        if let daysActive = rule.daysActive {
            if daysActive.isEmpty {
                activeDays = Set(0...6)
                isAllDay = true
            } else {
                let dayNames = [
                    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
                ]
                activeDays = Set(daysActive.compactMap { dayNames.firstIndex(of: $0) })
                isAllDay = activeDays.count == 7
            }
        }

        isLoading = false
    }

    // MARK: - Day Management

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
        activeDays = isAllDay ? Set(0...6) : []
    }

    // MARK: - Prayer Management

    func togglePrayer(_ rawValue: String) {
        if selectedPrayers.contains(rawValue) {
            selectedPrayers.remove(rawValue)
        } else {
            selectedPrayers.removeAll()
            selectedPrayers.insert(rawValue)

            if let prayer = PrayerTime(rawValue: rawValue) {
                let range = prayer.defaultTimeRange
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                if let s = formatter.date(from: range.start) { startTime = s }
                if let e = formatter.date(from: range.end) { endTime = e }
                expandedPicker = nil
            }
        }
    }

    // MARK: - App Selection

    func addMoreApps() { showAppPicker = true }

    func handleAppPickerSelection(_ selection: FamilyActivitySelection) async {
        appSelection = selection
        selectedApps = Set(selection.applicationTokens.compactMap { try? JSONEncoder().encode($0) })
        selectedCategories = Set(
            selection.categoryTokens.compactMap { try? JSONEncoder().encode($0) })
    }

    // MARK: - Save

    func saveSettings() async {
        isLoading = true
        errorMessage = nil

        guard authCenter.authorizationStatus == .approved else {
            errorMessage = "Screen Time permission not granted"
            isLoading = false
            return
        }

        var selection = FamilyActivitySelection()
        selection.applicationTokens = Set(
            selectedApps.compactMap { try? JSONDecoder().decode(ApplicationToken.self, from: $0) }
        )
        selection.categoryTokens = Set(
            selectedCategories.compactMap {
                try? JSONDecoder().decode(ActivityCategoryToken.self, from: $0)
            }
        )

        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            errorMessage = "Please select at least one app or category"
            isLoading = false
            return
        }

        guard endTime > startTime else {
            errorMessage = "End time must be later than start time"
            isLoading = false
            return
        }

        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)

        let daysActive: Set<String>
        if isAllDay || activeDays.isEmpty {
            daysActive = []
        } else {
            let dayNames = [
                "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
            ]
            daysActive = Set(activeDays.compactMap { dayNames[$0] })
        }

        do {
            let config = TimeLimitConfig(
                id: editingRuleId,
                name: settingsName.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "Time Limit" : settingsName,
                startTime: startComponents,
                endTime: endComponents,
                daysActive: daysActive
            )

            if let id = editingRuleId {
                try? await screenTimeRulesService.deleteTimeLimit(id: id)
            }

            try await screenTimeRulesService.setTimeLimitBlock(for: selection, config: config)
            hasSetupCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    // MARK: - Delete

    func deleteCurrentLimit() async {
        guard let limitId = editingRuleId else { return }
        isLoading = true
        do {
            try await screenTimeRulesService.deleteTimeLimit(id: limitId)
            hasSetupCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

}
