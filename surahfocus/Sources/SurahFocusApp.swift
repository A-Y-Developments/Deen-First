import RevenueCat
import SwiftData
import SwiftUI

@main
struct SurahFocusApp: App {
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
        #if DEBUG
            Purchases.logLevel = .debug
        #endif

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
            !apiKey.isEmpty
        else {
            fatalError("❌ RevenueCat API key missing. Check your .env file.")
        }

        Purchases.configure(withAPIKey: apiKey)
    }
}

// MARK: - Subscription Monitor

@MainActor
final class SubscriptionMonitor: ObservableObject {
    @Published var isPremium = false

    private var previousIsPremium: Bool? = nil  // nil = not yet loaded
    private var listenerTask: Task<Void, Never>?

    init() {
        startListening()
    }

    deinit {
        listenerTask?.cancel()
    }

    private func startListening() {
        listenerTask = Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                let isActive =
                    customerInfo.entitlements[AppConstants.revenueCatEntitlement]?.isActive == true

                // Detect true → false transition (subscription just expired)
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

        // Remove all shields and stop monitoring
        await DIContainer.shared.screenTimeRulesUseCase.pauseAllRules()

        // Tell RootView to hard-redirect to paywall
        NotificationCenter.default.post(name: .subscriptionExpired, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let subscriptionExpired = Notification.Name("subscriptionExpired")
    static let didPurchaseSubscription = Notification.Name("didPurchaseSubscription")
}
