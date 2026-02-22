import ManagedSettings
import UserNotifications

class ShieldActionExtension: ShieldActionDelegate {

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.aydev.surahfocus")
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)

        case .secondaryButtonPressed:
            sharedDefaults?.set(true, forKey: "reciteRequested")
            sharedDefaults?.synchronize()

            completionHandler(.defer)

        @unknown default:
            completionHandler(.close)
        }
    }
}
