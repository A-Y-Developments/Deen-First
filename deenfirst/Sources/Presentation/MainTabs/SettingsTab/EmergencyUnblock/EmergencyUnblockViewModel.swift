import Combine
import Foundation

@MainActor
final class EmergencyUnblockViewModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var quotaRemaining: Int = 2
    @Published var secondsUntilMidnight: Int? = nil

    private let screenTimeService: ScreenTimeRulesService
    private var countdownTimer: AnyCancellable?

    init(screenTimeService: ScreenTimeRulesService) {
        self.screenTimeService = screenTimeService
        refresh()
    }

    convenience init() {
        self.init(screenTimeService: DIContainer.shared.screenTimeRulesService)
    }

    func toggle() async {
        if isActive {
            await screenTimeService.deactivateEmergencyUnblock()
        } else {
            await screenTimeService.activateEmergencyUnblock()
        }
        refresh()
    }

    func refresh() {
        isActive = screenTimeService.isEmergencyUnblockActive
        quotaRemaining = screenTimeService.emergencyUnblockQuotaRemaining()

        if isActive {
            let expiry = AppGroupConstants.sharedDefaults?.double(
                forKey: AppGroupConstants.emergencyUnblockExpiryKey
            ) ?? 0
            startCountdown(expiry: expiry)
        } else {
            stopCountdown()
        }
    }

    // MARK: - Private

    private func startCountdown(expiry: TimeInterval) {
        stopCountdown()
        updateCountdown(expiry: expiry)

        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateCountdown(expiry: expiry)
            }
    }

    private func updateCountdown(expiry: TimeInterval) {
        let remaining = Int(expiry - Date().timeIntervalSince1970)
        if remaining <= 0 {
            stopCountdown()
            isActive = false
            quotaRemaining = screenTimeService.emergencyUnblockQuotaRemaining()
            Task { await screenTimeService.reblockEmergencyIfExpired() }
        } else {
            secondsUntilMidnight = remaining
        }
    }

    private func stopCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
        secondsUntilMidnight = nil
    }
}
