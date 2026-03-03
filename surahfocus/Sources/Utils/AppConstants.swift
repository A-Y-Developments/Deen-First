import Foundation

enum AppConstants {
    static let revenueCatEntitlement = "Surah Focus Premium"
    static let appName = "Deen First"
    static let minSessionSeconds = 120
    static let lastSubscriptionPriceKey = "lastSubscriptionPrice"
    static let reciteRequested  = "reciteRequested"
    static let unblockExpiryKey = "unblockExpiry"
    static let openAIKeyKey     = "openAIApiKey"
    static var bypassPaywall: Bool {
        Bundle.main.object(forInfoDictionaryKey: "BypassPaywall") as? String == "true"
    }

    enum Links {
        static let termsOfServiceURL = "https://deenfirst.co/terms-and-conditions"
        static let privacyPolicyURL = "https://deenfirst.co/privacy-policy"
        static let faqURL = "https://deenfirst.co"
        static let contactEmail = "mailto:hello@deenfirst.co"
    }
}
