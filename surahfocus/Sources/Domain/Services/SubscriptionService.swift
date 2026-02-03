import Foundation
import RevenueCat

protocol SubscriptionService {
    func checkSubscriptionStatus() async throws -> Bool
    func fetchOfferings() async throws -> Offerings
    func purchase(package: Package) async throws -> Bool
    func purchaseMonthly() async throws -> Bool
    func purchaseYearly() async throws -> Bool
    func restorePurchases() async throws -> Bool
    func getCustomerInfo() async throws -> CustomerInfo
}

final class SubscriptionServiceImpl: SubscriptionService {
    let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async throws -> Bool {
        let customerInfo = try await getCustomerInfo()
        let isActive = customerInfo.entitlements["Surah Focus Premium"]?.isActive == true

        // Update local user
        if let user = try await userRepository.getCurrentUser() {
            await updateSubscriptionStatus(for: user, customerInfo: customerInfo)
        }

        return isActive
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        return try await Purchases.shared.customerInfo()
    }

    // MARK: - Offerings

    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()

        guard offerings.current != nil else {
            throw SubscriptionError.noOfferingsAvailable
        }

        return offerings
    }

    // MARK: - Purchases

    func purchase(package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)

        // Update local user
        if let user = try await userRepository.getCurrentUser() {
            await updateSubscriptionStatus(for: user, customerInfo: result.customerInfo)
        }

        return result.customerInfo.entitlements["Surah Focus Premium"]?.isActive == true
    }

    func purchaseMonthly() async throws -> Bool {
        let offerings = try await fetchOfferings()

        guard let monthly = offerings.current?.monthly else {
            throw SubscriptionError.packageNotFound("monthly")
        }

        return try await purchase(package: monthly)
    }

    func purchaseYearly() async throws -> Bool {
        let offerings = try await fetchOfferings()

        guard let yearly = offerings.current?.annual else {
            throw SubscriptionError.packageNotFound("yearly")
        }

        return try await purchase(package: yearly)
    }

    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let isActive = customerInfo.entitlements["Surah Focus Premium"]?.isActive == true

        // Update local user
        if let user = try await userRepository.getCurrentUser() {
            await updateSubscriptionStatus(for: user, customerInfo: customerInfo)
        }

        return isActive
    }

    // MARK: - Helper Methods

    @MainActor
    private func updateSubscriptionStatus(for user: User, customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements["Surah Focus Premium"]
        user.isPremium = entitlement?.isActive == true
        user.subscriptionExpiryDate = entitlement?.expirationDate

        Task {
            try? await userRepository.updateUser(user)
        }
    }
}

// MARK: - Errors

enum SubscriptionError: Error, LocalizedError {
    case packageNotFound(String)
    case noOfferingsAvailable
    case purchaseCancelled
    case purchaseFailed(Error)
    case notEntitled

    var errorDescription: String? {
        switch self {
        case .packageNotFound(let type):
            return "Subscription package '\(type)' not found"
        case .noOfferingsAvailable:
            return "No subscription offerings available"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .notEntitled:
            return "You don't have access to this feature"
        }
    }
}

// MARK: - Entitlement Helper

extension SubscriptionService {
    var premiumEntitlementID: String { "Surah Focus Premium" }

    func isPremiumActive(customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements[premiumEntitlementID]?.isActive == true
    }

    func hasProAccess(customerInfo: CustomerInfo) -> Bool {
        isPremiumActive(customerInfo: customerInfo)
    }
}
