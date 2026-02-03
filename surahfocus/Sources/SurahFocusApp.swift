import SwiftUI
import SwiftData
import RevenueCat

@main
struct SurahFocusApp: App {
    @StateObject private var subscriptionMonitor = SubscriptionMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(DIContainer.shared.modelContainer)
                .environmentObject(subscriptionMonitor)
        }
    }

    init() {
        configureRevenueCat()
    }

    private func configureRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        let apiKey = ProcessInfo.processInfo.environment["TUIST_REVENUECAT_API_KEY"] ?? ""
        Purchases.configure(withAPIKey: apiKey)
    }
}

// MARK: - Subscription Monitor

@MainActor
final class SubscriptionMonitor: ObservableObject {
    @Published var isPremium = false

    private var customerInfoUpdateListener: Task<Void, Never>?

    init() {
        startListening()
    }

    deinit {
        customerInfoUpdateListener?.cancel()
    }

    private func startListening() {
        customerInfoUpdateListener = Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.isPremium = customerInfo.entitlements[AppConstants.revenueCatEntitlement]?.isActive == true
                    NotificationCenter.default.post(
                        name: .subscriptionStatusChanged,
                        object: nil,
                        userInfo: ["isActive": isPremium]
                    )
                }
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
