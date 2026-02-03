import SwiftUI
import RevenueCat

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?
    @Published var errorMessage: String?
    @Published var showError = false

    enum SubscriptionPlan {
        case monthly
        case yearly
    }

    func loadOfferings() async {
        isLoading = true

        do {
            let offerings = try await DIContainer.shared.subscriptionService.fetchOfferings()
            monthlyPackage = offerings.current?.monthly
            yearlyPackage = offerings.current?.annual
        } catch {
            errorMessage = "Failed to load subscription options"
            showError = true
        }

        isLoading = false
    }

    func purchase() async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let success: Bool

            switch selectedPlan {
            case .monthly:
                success = try await DIContainer.shared.subscriptionService.purchaseMonthly()
            case .yearly:
                success = try await DIContainer.shared.subscriptionService.purchaseYearly()
            }

            return success

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            return try await DIContainer.shared.subscriptionService.restorePurchases()
        } catch {
            errorMessage = "No purchases to restore"
            showError = true
            return false
        }
    }

    var selectedPackagePrice: String {
        switch selectedPlan {
        case .monthly:
            return monthlyPackage?.localizedPriceString ?? "$4.99"
        case .yearly:
            return yearlyPackage?.localizedPriceString ?? "$29.99"
        }
    }

    var trialDurationText: String {
        switch selectedPlan {
        case .monthly:
            return "3-day"
        case .yearly:
            return "7-day"
        }
    }
}
