import SwiftUI
import FamilyControls

@MainActor
final class TimeLimitViewModel: ObservableObject {
    @Published var settingsName: String = ""
    @Published var selectedApps: Set<Data> = []
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
    @Published var showDeleteConfirmation = false

    enum TimePickerType: String, Identifiable {
        case start
        case end

        var id: String { rawValue }
    }

    private let timeLimitService: TimeLimitService
    private let userRepository: UserRepository
    private let authCenter: AuthorizationCenter
    private(set) var skipAuthCheck: Bool = false
    private(set) var editingLimitId: UUID?

    var isEditMode: Bool { editingLimitId != nil }

    let availablePrayers = ["subuh", "zuhr", "asr", "maghrib", "isya"]

    init(limitId: UUID? = nil, timeLimitService: TimeLimitService, userRepository: UserRepository, authCenter: AuthorizationCenter = .shared, skipAuthCheck: Bool = false) {
        self.timeLimitService = timeLimitService
        self.userRepository = userRepository
        self.authCenter = authCenter
        self.skipAuthCheck = skipAuthCheck
        self.editingLimitId = limitId

        if let limitId = limitId {
            Task {
                await loadExistingDataFromRule(limitId: limitId)
            }
        }
    }

    convenience init() {
        self.init(
            timeLimitService: DIContainer.shared.timeLimitSettingsService,
            userRepository: DIContainer.shared.userRepository
        )
    }

    func loadExistingData(limitId: UUID?) async {
        guard let limitId = limitId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let userId = try await getCurrentUserId()
            let limits = try await timeLimitService.getTimeLimits(userId: userId)

            if let limit = limits.first(where: { $0.id == limitId }) {
                settingsName = limit.name
                selectedApps = Set(limit.appTokens)

                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                if let startDate = formatter.date(from: limit.startTime) {
                    startTime = startDate
                }
                if let endDate = formatter.date(from: limit.endTime) {
                    endTime = endDate
                }

                activeDays = Set(limit.activeDays)
                isAllDay = limit.isAllDay
                selectedPrayers = Set(limit.prayerTimes)
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

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let startTimeString = formatter.string(from: startTime)
            let endTimeString = formatter.string(from: endTime)

            guard validateTimeRange() else {
                errorMessage = "End time must be later than start time"
                isLoading = false
                return
            }

            let activeDaysArray = isAllDay ? Array(0...6) : Array(activeDays).sorted()

            if activeDaysArray.isEmpty {
                errorMessage = "Please select at least one day"
                isLoading = false
                return
            }

            if isEditMode, let limitId = editingLimitId {
                // Update existing
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let daysActive = activeDays.isEmpty ? Set(DayHelper.allDayNames) : Set(activeDaysArray.map { dayNames[$0] })
                let calendar = Calendar.current
                let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
                let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
                let config = TimeOfDayConfig(
                    id: limitId,
                    name: settingsName.isEmpty ? "My Time Limit" : settingsName,
                    startTime: startComps,
                    endTime: endComps,
                    daysActive: daysActive
                )
                let useCase = DIContainer.shared.screenTimeRulesUseCase
                try await useCase.updateTimeOfDayBlock(id: limitId, for: appSelection, config: config)
            } else {
                // Create new
                try await timeLimitService.createTimeLimit(
                    userId: userId,
                    name: settingsName.isEmpty ? "My Time Limit" : settingsName,
                    appTokens: appTokens,
                    startTime: startTimeString,
                    endTime: endTimeString,
                    activeDays: activeDaysArray,
                    isAllDay: isAllDay,
                    prayerTimes: Array(selectedPrayers)
                )
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

    func togglePrayer(_ prayer: String) {
        if selectedPrayers.contains(prayer) {
            selectedPrayers.remove(prayer)
        } else {
            selectedPrayers.insert(prayer)
        }
    }

    func validateTimeRange() -> Bool {
        return endTime > startTime
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
            throw NSError(domain: "TimeLimitViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
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

    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
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

    var appsCount: Int {
        selectedApps.count
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

    func addMoreApps() {
        showAppPicker = true
    }

    func handleTimePickerUpdate(_ pickerType: TimePickerType) {
        // Called when time picker is dismissed
        // Time values are already updated via binding
    }

    func loadExistingDataFromRule(limitId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let useCase = DIContainer.shared.screenTimeRulesUseCase
            guard let rule = useCase.getRule(id: limitId), rule.type == .timeOfDay else {
                errorMessage = "Block not found"
                isLoading = false
                return
            }

            settingsName = rule.name

            let selection = rule.getFamilyActivitySelection()
            appSelection = selection
            let tokens = selection.applicationTokens.compactMap { try? JSONEncoder().encode($0) }
            selectedApps = Set(tokens)

            if let startTime = rule.getStartTimeComponents(), let endTime = rule.getEndTimeComponents() {
                let calendar = Calendar.current
                if let startDate = calendar.date(from: startTime), let endDate = calendar.date(from: endTime) {
                    self.startTime = startDate
                    self.endTime = endDate
                }
            }

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
            try await useCase.deleteTimeOfDay(id: limitId)
            hasSetupCompleted = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
