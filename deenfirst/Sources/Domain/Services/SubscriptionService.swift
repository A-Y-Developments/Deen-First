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
    func isPremiumActive(customerInfo: CustomerInfo) -> Bool
}

final class SubscriptionServiceImpl: SubscriptionService {

    init() {}

    func checkSubscriptionStatus() async throws -> Bool {
        let info = try await getCustomerInfo()
        return isPremiumActive(customerInfo: info)
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        guard offerings.current != nil else {
            throw SubscriptionError.noOfferingsAvailable
        }
        return offerings
    }

    func purchase(package: Package) async throws -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            return isPremiumActive(customerInfo: result.customerInfo)
        } catch {
            let nsError = error as NSError
            if nsError.domain == ErrorCode.errorDomain,
               nsError.code == ErrorCode.purchaseCancelledError.rawValue {
                throw SubscriptionError.purchaseCancelled
            }
            throw SubscriptionError.purchaseFailed(error)
        }
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
        return isPremiumActive(customerInfo: info)
    }
}

extension SubscriptionServiceImpl {
    static let entitlementID = AppConstants.revenueCatEntitlement
}

extension SubscriptionService {
    func isPremiumActive(customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements[AppConstants.revenueCatEntitlement]?.isActive == true
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
        case .packageNotFound(let type):
            return "Package '\(type)' not found."
        case .noOfferingsAvailable:
            return "No offerings available."
        case .purchaseCancelled:
            return nil
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .notEntitled:
            return "You don't have access to this feature."
        }
    }
}
