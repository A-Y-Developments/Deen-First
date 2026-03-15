import RevenueCat
import SwiftUI

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?
    @Published var errorMessage: String?
    @Published var showError = false

    @Published var monthlyTrialEligible: Bool? = nil
    @Published var yearlyTrialEligible: Bool? = nil

    /// Set before presenting from settings — "monthly" or "yearly"
    var currentActivePlan: String? = nil  // 👈 new

    enum SubscriptionPlan {
        case monthly
        case yearly

        var key: String {
            switch self {
            case .monthly: return "monthly"
            case .yearly: return "yearly"
            }
        }
    }

    func loadOfferings() async {
        isLoading = true
        do {
            let offerings = try await DIContainer.shared.subscriptionService.fetchOfferings()
            monthlyPackage = offerings.current?.monthly
            yearlyPackage = offerings.current?.annual
            await checkTrialEligibility()
        } catch {
            errorMessage = "Failed to load subscription options"
            showError = true
        }
        isLoading = false
    }

    private func checkTrialEligibility() async {
        var productIdentifiers: [String] = []
        if let monthly = monthlyPackage {
            productIdentifiers.append(monthly.storeProduct.productIdentifier)
        }
        if let yearly = yearlyPackage {
            productIdentifiers.append(yearly.storeProduct.productIdentifier)
        }
        guard !productIdentifiers.isEmpty else { return }

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: productIdentifiers)

        if let monthly = monthlyPackage {
            monthlyTrialEligible =
                eligibility[monthly.storeProduct.productIdentifier]?.status == .eligible
        }
        if let yearly = yearlyPackage {
            yearlyTrialEligible =
                eligibility[yearly.storeProduct.productIdentifier]?.status == .eligible
        }
    }

    func purchase() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let package = selectedPlan == .monthly ? monthlyPackage : yearlyPackage else {
                throw SubscriptionError.packageNotFound(
                    selectedPlan == .monthly ? "monthly" : "yearly")
            }

            let success = try await DIContainer.shared.subscriptionService.purchase(
                package: package)

            if success {
                UserDefaults.standard.set(
                    package.storeProduct.localizedPriceString,
                    forKey: AppConstants.lastSubscriptionPriceKey
                )
            }

            return success
        } catch SubscriptionError.purchaseCancelled {
            return false
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
            let restored = try await DIContainer.shared.subscriptionService.restorePurchases()
            if !restored {
                errorMessage =
                    "No active subscription found. If you believe this is an error, contact support."
                showError = true
            }
            return restored
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    // MARK: - Display Helpers

    var selectedPackagePrice: String {
        let package = selectedPlan == .monthly ? monthlyPackage : yearlyPackage
        return package?.localizedPriceString ?? (selectedPlan == .monthly ? "$4.99" : "$29.99")
    }

    var monthlyDisplayPrice: String {
        return monthlyPackage?.localizedPriceString ?? "$4.99"
    }

    var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyPackage else { return "$3.33/Mo" }

        let yearlyPrice = yearly.storeProduct.price as Decimal
        let monthlyEquivalent = yearlyPrice / 12

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.storeProduct.priceFormatter?.locale ?? .current

        let number = monthlyEquivalent as NSDecimalNumber
        let formatted = formatter.string(from: number) ?? "3.33"
        return "\(formatted)/Mo"
    }

    var currentPlanHasTrial: Bool {
        switch selectedPlan {
        case .monthly: return monthlyTrialEligible == true
        case .yearly: return yearlyTrialEligible == true
        }
    }

    /// Whether the currently selected plan is what the user already owns
    var isSelectedPlanCurrent: Bool {
        guard let active = currentActivePlan else { return false }
        return selectedPlan.key == active
    }

    var ctaButtonLabel: String {
        if let active = currentActivePlan {
            if selectedPlan.key == active {
                return "Already Subscribed"
            } else {
                // Yearly is always more expensive — switching from monthly to yearly = upgrade
                return selectedPlan == .yearly ? "Upgrade to Yearly" : "Switch to Monthly"
            }
        }
        return currentPlanHasTrial ? "Start My Free Trial" : "Subscribe Now"
    }

    /// Badge text on the plan card — "Current Plan" takes priority over trial badge
    func trialBadgeText(for plan: SubscriptionPlan) -> String? {
        // If this plan is their current active plan, show that instead
        if let active = currentActivePlan, plan.key == active {
            return "Current Plan"
        }

        let eligible = plan == .monthly ? monthlyTrialEligible : yearlyTrialEligible
        guard eligible == true else { return nil }

        let package = plan == .monthly ? monthlyPackage : yearlyPackage
        guard let discount = package?.storeProduct.introductoryDiscount else { return nil }

        let value = discount.subscriptionPeriod.value
        let unit = discount.subscriptionPeriod.unit

        switch unit {
        case .day: return "\(value)-day Free Trial"
        case .week: return "\(value * 7)-day Free Trial"
        case .month: return "\(value)-month Free Trial"
        case .year: return "\(value)-year Free Trial"
        @unknown default: return "\(value)-day Free Trial"
        }
    }
}
