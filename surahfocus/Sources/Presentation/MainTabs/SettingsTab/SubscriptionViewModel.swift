import Foundation
import RevenueCat

@MainActor
final class SubscriptionViewModel: ObservableObject {

    // MARK: - Published
    @Published var isLoading = true
    @Published var isPremium = false
    @Published var planLabel: String = ""
    @Published var renewalText: String = ""
    @Published var currentPlanType: String? = nil // "monthly" or "yearly"

    // MARK: - Dependencies
    private let subscriptionService: SubscriptionService

    init(subscriptionService: SubscriptionService = DIContainer.shared.subscriptionService) {
        self.subscriptionService = subscriptionService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let info = try? await subscriptionService.getCustomerInfo() else { return }

        let entitlement = info.entitlements[AppConstants.revenueCatEntitlement]
        isPremium = entitlement?.isActive == true

        guard isPremium, let entitlement else {
            currentPlanType = nil
            return
        }

        // Plan label + currentPlanType — derived from product identifier
        let productId = entitlement.productIdentifier.lowercased()
        if productId.contains("yearly") || productId.contains("annual") {
            planLabel = "Yearly plan is active"
            currentPlanType = "yearly"
        } else if productId.contains("monthly") {
            planLabel = "Monthly plan is active"
            currentPlanType = "monthly"
        } else {
            planLabel = "Plan is active"
            currentPlanType = nil
        }

        // Renewal date + price
        if let expiryDate = entitlement.expirationDate {
            let formatted = expiryDate.formatted(.dateTime.day().month(.abbreviated).year())
            if let price = UserDefaults.standard.string(forKey: AppConstants.lastSubscriptionPriceKey) {
                renewalText = "Your plan will automatically renew on \(formatted). You'll be charged \(price)"
            } else {
                renewalText = "Your plan will automatically renew on \(formatted)."
            }
        } else {
            renewalText = "You have lifetime access. No renewal needed."
        }
    }
}