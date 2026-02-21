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

    init() {}

    // MARK: - Status

    func checkSubscriptionStatus() async throws -> Bool {
        let info = try await getCustomerInfo()
        return info.entitlements[Self.entitlementID]?.isActive == true
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
        return result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
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
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements[Self.entitlementID]?.isActive == true
    }
}

// MARK: - Constants + Errors

extension SubscriptionServiceImpl {
    static let entitlementID = "Surah Focus Premium"
}

extension SubscriptionService {
    func isPremiumActive(customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements["Surah Focus Premium"]?.isActive == true
    }
}

enum SubscriptionError: Error, LocalizedError {
    case packageNotFound(String)
    case noOfferingsAvailable
    case purchaseCancelled
    case purchaseFailed(Error)
    case notEntitled

    var errorDescription: String? {
        switch self {
        case .packageNotFound(let type): return "Package '\(type)' not found"
        case .noOfferingsAvailable:      return "No offerings available"
        case .purchaseCancelled:         return "Purchase was cancelled"
        case .purchaseFailed(let e):     return "Purchase failed: \(e.localizedDescription)"
        case .notEntitled:               return "You don't have access to this feature"
        }
    }
}