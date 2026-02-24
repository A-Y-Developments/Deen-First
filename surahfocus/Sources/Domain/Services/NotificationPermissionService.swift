import Foundation
import UserNotifications

protocol NotificationPermissionService {
    func requestAuthorizationIfNeeded() async -> Bool
}

final class NotificationPermissionServiceImpl: NotificationPermissionService {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaultsKey = "hasRequestedNotificationPermission"

    func requestAuthorizationIfNeeded() async -> Bool {
        if UserDefaults.standard.bool(forKey: userDefaultsKey) {
            return false
        }

        let granted = await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }

        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        return granted
    }
}
