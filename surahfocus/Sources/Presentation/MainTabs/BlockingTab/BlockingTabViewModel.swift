import SwiftUI
import FamilyControls

@MainActor
final class BlockingTabViewModel: ObservableObject {
    @Published var appLimits: [AppLimit] = []
    @Published var timeLimits: [TimeLimitSettings] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showActivityPicker = false
    @Published var appSelection = FamilyActivitySelection()

    private let appLimitService: AppLimitService
    private let timeLimitService: TimeLimitService
    private let userRepository: UserRepository

    init(
        appLimitService: AppLimitService,
        timeLimitService: TimeLimitService,
        userRepository: UserRepository
    ) {
        self.appLimitService = appLimitService
        self.timeLimitService = timeLimitService
        self.userRepository = userRepository
    }

    convenience init() {
        self.init(
            appLimitService: DIContainer.shared.appLimitService,
            timeLimitService: DIContainer.shared.timeLimitSettingsService,
            userRepository: DIContainer.shared.userRepository
        )
    }

    func loadBlockedApps() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let user = try await userRepository.getCurrentUser() else {
                errorMessage = "User not found"
                isLoading = false
                return
            }

            async let appLimitsResult = appLimitService.getAppLimits()
            async let timeLimitsResult = timeLimitService.getTimeLimits(userId: user.id)

            appLimits = try await appLimitsResult.filter { $0.isActive }
            timeLimits = try await timeLimitsResult.filter { $0.isActive }
            isLoading = false

            logTimeBlockSettings()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func logTimeBlockSettings() {
        print("=== TIME BLOCK SETTINGS LOG ===")

        for limit in appLimits {
            print("\nType: App Limit")
            print("Name: \(limit.name)")
            print("App Selection: 0 Category, \(limit.appTokens.count) Apps")
            let hours = limit.dailyLimitMinutes / 60
            let mins = limit.dailyLimitMinutes % 60
            if hours > 0 {
                print("Time: \(hours) hour\(hours > 1 ? "s" : "")\(mins > 0 ? " \(mins) min" : "")")
            } else {
                print("Time: \(mins) min")
            }
            print("Days: All Days")
        }

        for limit in timeLimits {
            print("\nType: Time Limit")
            print("Name: \(limit.name)")
            print("App Selection: 0 Category, \(limit.appTokens.count) Apps")
            print("Time: \(limit.startTime) - \(limit.endTime)")
            print("Days: All Days")
        }

        print("\n==============================")
    }

    func deleteAppLimit(_ limit: AppLimit) async {
        do {
            limit.isActive = false
            try await appLimitService.updateAppLimit(limit)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTimeLimit(_ limit: TimeLimitSettings) async {
        do {
            limit.isActive = false
            try await timeLimitService.updateTimeLimit(limit)
            await loadBlockedApps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var blockedAppsCount: Int {
        appLimits.count + timeLimits.count
    }

    var hasApps: Bool {
        !appLimits.isEmpty || !timeLimits.isEmpty
    }
}
