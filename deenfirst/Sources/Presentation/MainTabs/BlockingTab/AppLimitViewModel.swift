//
//  AppLimitViewModel.swift
//  DeenFirst
//

import FamilyControls
import ManagedSettings
import SwiftUI

@MainActor
final class AppLimitViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
    @Published var selectedCategories: Set<Data> = []
    @Published var selectedHours: Int = 1
    @Published var selectedMinutes: Int = 0
    @Published var activeDays: Set<Int> = Set(0...6)
    @Published var isAllDay: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showAppPicker: Bool = false
    @Published var appSelection = FamilyActivitySelection()
    @Published var hasSetupCompleted: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var isHardMode: Bool = false
    @Published var isLockEditingEnabled: Bool = false
    @Published var showHardModeConfirmation: Bool = false
    @Published var showPendingChangeSheet: Bool = false

    // MARK: - Edit Mode

    var isEditMode: Bool { editingRuleId != nil }
    private(set) var editingRuleId: UUID?
    private var originalLockEditingEnabled: Bool = false

    // MARK: - Dependencies

    private let screenTimeRulesService: ScreenTimeRulesService
    private let pendingChangeService: PendingChangeService
    private let authCenter: AuthorizationCenter

    // MARK: - Init

    init(
        screenTimeRulesService: ScreenTimeRulesService,
        pendingChangeService: PendingChangeService,
        authCenter: AuthorizationCenter = .shared
    ) {
        self.screenTimeRulesService = screenTimeRulesService
        self.pendingChangeService = pendingChangeService
        self.authCenter = authCenter
    }

    convenience init() {
        self.init(
            screenTimeRulesService: DIContainer.shared.screenTimeRulesService,
            pendingChangeService: DIContainer.shared.pendingChangeService
        )
    }

    // MARK: - Computed Properties

    var dailyLimitMinutes: Int { selectedHours * 60 + selectedMinutes }

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
            && dailyLimitMinutes > 0
            && !activeDays.isEmpty
    }

    var timeLimitText: String {
        let h = selectedHours
        let m = selectedMinutes
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
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

        let limitMins = (rule.limitSeconds ?? 3600) / 60
        selectedHours = limitMins / 60
        selectedMinutes = limitMins % 60

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

        isHardMode = rule.isHardMode
        isLockEditingEnabled = rule.isLockEditingEnabled
        originalLockEditingEnabled = rule.isLockEditingEnabled
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

    // MARK: - Hard Mode

    /// Called when the user taps the "Hard Mode" option. If Hard Mode is already
    /// on this is a no-op; otherwise a confirmation dialog is shown disclosing
    /// that Lock Editing will auto-enable. The flags flip only after explicit
    /// confirmation via `confirmEnableHardMode`.
    func requestEnableHardMode() {
        guard !isHardMode else { return }
        showHardModeConfirmation = true
    }

    func confirmEnableHardMode() {
        isHardMode = true
        isLockEditingEnabled = true
        showHardModeConfirmation = false
    }

    func cancelEnableHardMode() {
        showHardModeConfirmation = false
    }

    /// Toggles Hard Mode off without touching Lock Editing. The two flags
    /// are coupled on enable (via the confirmation) but decoupled on disable:
    /// users can leave Lock Editing on after turning Hard Mode off, or toggle
    /// it separately via the Lock Editing control.
    func disableHardMode() {
        isHardMode = false
    }

    // MARK: - Lock Editing

    func handleLockEditingToggle(to newValue: Bool) {
        if newValue || !isEditMode || !originalLockEditingEnabled {
            isLockEditingEnabled = newValue
        } else {
            showPendingChangeSheet = true
        }
    }

    func scheduleLockEditingDisable() {
        guard let ruleId = editingRuleId,
              let rule = screenTimeRulesService.getRule(id: ruleId) else { return }
        Task {
            await pendingChangeService.createPendingChange(
                for: rule,
                changeType: PendingChangeType.disableLockEditing.rawValue,
                pendingData: nil
            )
            showPendingChangeSheet = false
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
            let config = AppLimitConfig(
                id: editingRuleId,
                name: settingsName.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "App Limit" : settingsName,
                timeLimit: .custom(dailyLimitMinutes * 60),
                daysActive: daysActive,
                isHardMode: isHardMode,
                isLockEditingEnabled: isLockEditingEnabled
            )

            if editingRuleId != nil {
                try await screenTimeRulesService.editAppLimitRule(for: selection, config: config)
            } else {
                try await screenTimeRulesService.setAppLimitBlock(for: selection, config: config)
            }
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
            try await screenTimeRulesService.deleteRule(id: limitId)
            hasSetupCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
