import XCTest
import RevenueCat
@testable import SurahFocus

@MainActor
final class PaywallViewModelTests: XCTestCase {
    var viewModel: PaywallViewModel!
    var mockSubscriptionService: MockSubscriptionService!

    override func setUp() {
        mockSubscriptionService = MockSubscriptionService()
        viewModel = PaywallViewModel(subscriptionService: mockSubscriptionService)
    }

    override func tearDown() {
        viewModel = nil
        mockSubscriptionService = nil
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.selectedPlan, .yearly)
        XCTAssertNil(viewModel.monthlyPackage)
        XCTAssertNil(viewModel.yearlyPackage)
    }

    func testTrialDurationTextForMonthly() {
        viewModel.selectedPlan = .monthly
        XCTAssertEqual(viewModel.trialDurationText, "3-day")
    }

    func testTrialDurationTextForYearly() {
        viewModel.selectedPlan = .yearly
        XCTAssertEqual(viewModel.trialDurationText, "7-day")
    }
}

// MARK: - Mock Subscription Service

class MockSubscriptionService: SubscriptionService {
    var shouldReturnPremium = true
    var shouldThrowError = false

    func checkSubscriptionStatus() async throws -> Bool {
        return shouldReturnPremium
    }

    func fetchOfferings() async throws -> RevenueCat.Offerings {
        fatalError("Use real RevenueCat for integration tests")
    }

    func purchase(package: Package) async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }

    func purchaseMonthly() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }

    func purchaseYearly() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }

    func restorePurchases() async throws -> Bool {
        if shouldThrowError {
            throw SubscriptionError.purchaseCancelled
        }
        return shouldReturnPremium
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        fatalError("Use real RevenueCat for integration tests")
    }
}
