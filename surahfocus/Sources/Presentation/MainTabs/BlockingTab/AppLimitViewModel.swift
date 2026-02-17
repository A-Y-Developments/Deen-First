import SwiftUI
import FamilyControls

@MainActor
final class AppLimitViewModel: ObservableObject {
    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
    @Published var dailyLimitMinutes: Int = 60
    @Published var activeDays: Set<Int> = []
    @Published var isAllDay: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showAppPicker: Bool = false
    @Published var appSelection = FamilyActivitySelection()
    @Published var hasSetupCompleted: Bool = false
    @Published var showDeleteConfirmation = false
    @Published var showTimePicker: Bool = false

    private let appLimitService: AppLimitService
    private let userRepository: UserRepository
    private let authCenter: AuthorizationCenter
    private(set) var skipAuthCheck: Bool = false
    private(set) var editingLimitId: UUID?

    var isEditMode: Bool { editingLimitId != nil }

    init(limitId: UUID? = nil, isAllDay: Bool = false, appLimitService: AppLimitService, userRepository: UserRepository, authCenter: AuthorizationCenter = .shared, skipAuthCheck: Bool = false) {
        self.appLimitService = appLimitService
        self.userRepository = userRepository
        self.authCenter = authCenter
        self.skipAuthCheck = skipAuthCheck
        self.editingLimitId = limitId
        self.isAllDay = isAllDay

        if let limitId = limitId {
            Task {
                await loadExistingDataFromRule(limitId: limitId)
            }
        }
    }

    convenience init() {
        self.init(
            appLimitService: DIContainer.shared.appLimitService,
            userRepository: DIContainer.shared.userRepository
        )
    }

    func loadExistingData(limitId: UUID?) async {
        guard let limitId = limitId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let limits = try await appLimitService.getAppLimits()

            if let limit = limits.first(where: { $0.id == limitId }) {
                settingsName = limit.name
                selectedApps = Set(limit.appTokens)
                dailyLimitMinutes = limit.dailyLimitMinutes
                activeDays = Set(limit.activeDays)
                isAllDay = limit.isAllDay
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func saveSettings() async {
        isLoading = true
        errorMessage = nil

        do {
            if !skipAuthCheck {
                guard authCenter.authorizationStatus == .approved else {
                    errorMessage = "Screen Time permission not granted"
                    isLoading = false
                    return
                }
            }

            let userId = try await getCurrentUserId()
            let appTokens = Array(selectedApps)

            if appTokens.isEmpty {
                errorMessage = "Please select at least one app"
                isLoading = false
                return
            }

            let activeDaysArray = isAllDay ? Array(0...6) : Array(activeDays).sorted()

            if activeDaysArray.isEmpty {
                errorMessage = "Please select at least one day"
                isLoading = false
                return
            }

            // Use ScreenTimeRulesUseCase for both create and update
            let useCase = DIContainer.shared.screenTimeRulesUseCase

            if isEditMode, let limitId = editingLimitId {
                // Update existing
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let daysActive = activeDays.isEmpty ? Set(DayHelper.allDayNames) : Set(activeDaysArray.map { dayNames[$0] })
                let config = TimeLimitConfig(
                    id: limitId,
                    name: settingsName.isEmpty ? "My App Limit" : settingsName,
                    timeLimit: .fromMinutes(dailyLimitMinutes),
                    daysActive: daysActive
                )
                try await useCase.updateTimeLimit(id: limitId, for: appSelection, config: config)
            } else {
                // Create new - use TimeLimitConfig for time-based limit (not immediate blocking)
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let daysActive = activeDays.isEmpty ? Set(DayHelper.allDayNames) : Set(activeDaysArray.map { dayNames[$0] })
                let config = TimeLimitConfig(
                    id: nil,
                    name: settingsName.isEmpty ? "My App Limit" : settingsName,
                    timeLimit: .fromMinutes(dailyLimitMinutes),
                    daysActive: daysActive
                )
                try await useCase.setTimeLimit(for: appSelection, config: config)
            }

            hasSetupCompleted = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func toggleAllDay() {
        isAllDay.toggle()
        if isAllDay {
            activeDays = Set(0...6)
        }
    }

    func toggleDay(_ day: Int) {
        if activeDays.contains(day) {
            activeDays.remove(day)
        } else {
            activeDays.insert(day)
        }
        isAllDay = activeDays.count == 7
    }

    func handleAppPickerSelection(_ selection: FamilyActivitySelection) async {
        appSelection = selection

        do {
            let tokens = selection.applicationTokens.map { try? JSONEncoder().encode($0) }.compactMap { $0 }
            selectedApps = Set(tokens)
        } catch {
            errorMessage = "Failed to process app selection"
        }
    }

    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userRepository.getCurrentUser() else {
            throw NSError(domain: "AppLimitViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user.id
    }

    var daysText: String {
        if isAllDay { return "Every day" }
        if activeDays.isEmpty { return "No days selected" }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = Array(activeDays).sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }

    var timeLimitText: String {
        if dailyLimitMinutes < 60 {
            return "\(dailyLimitMinutes) min/day"
        }
        let hours = dailyLimitMinutes / 60
        let mins = dailyLimitMinutes % 60
        if mins == 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")/day"
        }
        return "\(hours)h \(mins)m/day"
    }

    var appsCount: Int {
        selectedApps.count
    }

    func addMoreApps() {
        showAppPicker = true
    }

    func loadExistingDataFromRule(limitId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let useCase = DIContainer.shared.screenTimeRulesUseCase
            guard let rule = useCase.getRule(id: limitId) else {
                errorMessage = "Block not found"
                isLoading = false
                return
            }

            settingsName = rule.name
            dailyLimitMinutes = (rule.limitSeconds ?? 3600) / 60

            let selection = rule.getFamilyActivitySelection()
            appSelection = selection
            let tokens = selection.applicationTokens.compactMap { try? JSONEncoder().encode($0) }
            selectedApps = Set(tokens)

            if let daysActive = rule.daysActive {
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                activeDays = Set(daysActive.compactMap { dayNames.firstIndex(of: $0) })
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func deleteCurrentLimit() async {
        guard let limitId = editingLimitId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let useCase = DIContainer.shared.screenTimeRulesUseCase
            try await useCase.deleteTimeLimit(id: limitId)
            hasSetupCompleted = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
