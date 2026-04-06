import RevenueCat
import SwiftData
import SwiftUI
import UserNotifications

@main
struct DeenFirstApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var subscriptionMonitor = SubscriptionMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(DIContainer.shared.modelContainer)
                .environmentObject(subscriptionMonitor)
                .preferredColorScheme(.dark)
        }
    }

    init() {
        configureRevenueCat()
    }

    private func configureRevenueCat() {
        Purchases.logLevel = .verbose

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
            !apiKey.isEmpty
        else {
            fatalError("❌ RevenueCat API key missing. Check your .env file.")
        }

        Purchases.configure(withAPIKey: apiKey)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when user taps a notification (e.g. reblock notification after temp unblock expires).
    // The actual reblock logic runs in willEnterForeground — this just ensures
    // the delegate is wired up so foreground presentation also works correctly.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Subscription Monitor

@MainActor
final class SubscriptionMonitor: ObservableObject {
    @Published var isPremium = false

    private var previousIsPremium: Bool? = nil
    private var listenerTask: Task<Void, Never>?

    init() {
        startListening()
    }

    deinit {
        listenerTask?.cancel()
    }

    private func startListening() {
        guard !AppConstants.bypassPaywall else {
            isPremium = true
            return
        }

        listenerTask = Task {
            do {
                let initialInfo = try await Purchases.shared.customerInfo()
                let initialIsActive =
                    initialInfo.entitlements[AppConstants.revenueCatEntitlement]?.isActive == true
                previousIsPremium = initialIsActive
                isPremium = initialIsActive
            } catch {
                print("[SubscriptionMonitor] Failed to fetch initial customer info: \(error)")
            }

            for await customerInfo in Purchases.shared.customerInfoStream {
                let isActive =
                    customerInfo.entitlements[AppConstants.revenueCatEntitlement]?.isActive == true

                if let previous = previousIsPremium, previous == true, isActive == false {
                    await handleSubscriptionExpired()
                }

                previousIsPremium = isActive
                isPremium = isActive

                NotificationCenter.default.post(
                    name: .subscriptionStatusChanged,
                    object: nil,
                    userInfo: ["isActive": isActive]
                )
            }
        }
    }

    private func handleSubscriptionExpired() async {
        print("[SubscriptionMonitor] Subscription expired — pausing all Screen Time rules")
        await DIContainer.shared.screenTimeRulesService.pauseAllRules()
        NotificationCenter.default.post(name: .subscriptionExpired, object: nil)
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var openAIApiKey: String {
        guard let key = object(forInfoDictionaryKey: "OpenAIAPIKey") as? String, !key.isEmpty else {
            assertionFailure("⚠️ OpenAIAPIKey missing in Info.plist — check your .env file")
            return ""
        }
        return key
    }
}
