# RevenueCat Integration Guide - Deen First

## Overview
This guide walks through the complete RevenueCat integration for Deen First app.

---

## ✅ Already Implemented

### 1. SDK Installation
RevenueCat is already installed via Tuist in `Tuist/Package.swift`:
```swift
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0")
```

### 2. Configuration
RevenueCat is configured in `Sources/DeenFirstApp.swift`:
- API Key: `test_GigTjmiydMdJecOcMpeoxAtxtyi` (test mode)
- Customer info streaming enabled via `customerInfoStream`
- Delegate pattern for real-time subscription updates

### 3. Core Services
- `SubscriptionService` protocol with full async/await support
- `SubscriptionServiceImpl` with purchase, restore, and entitlement checking
- `PaywallViewModel` for UI state management
- `PaywallView` with beautiful SwiftUI paywall

---

## 🔧 Next Steps: RevenueCat Dashboard Setup

### Step 1: Configure Products in RevenueCat Dashboard

1. Go to https://app.revenuecat.com
2. Select your project
3. Navigate to **Products** > **iOS**

#### Create Products

**Monthly Product:**
- Product ID: `com.aydev.deenfirst.monthly`
- Display Name: `Deen First Monthly`
- Price: `$4.99/month`
- Trial: 3 days

**Yearly Product:**
- Product ID: `com.aydev.deenfirst.yearly`
- Display Name: `Deen First Yearly`
- Price: `$29.99/year`
- Trial: 7 days

### Step 2: Create Offering

1. Navigate to **Offerings** in RevenueCat dashboard
2. Create a new offering called **"default"**
3. Add both products:
   - Monthly package → `com.aydev.deenfirst.monthly`
   - Annual package → `com.aydev.deenfirst.yearly`

### Step 3: Create Entitlement

1. Navigate to **Entitlements**
2. Create entitlement: **"premium"**
3. Attach both products to this entitlement

### Step 4: Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** > **Deen First**
3. **Subscriptions** > **Create Subscription Group** ("Deen First Premium")

#### Add Subscription - Monthly:
- Product ID: `com.aydev.deenfirst.monthly`
- Name: "Monthly Premium"
- Price: $4.99
- Duration: 1 Month
- Offers: 3-day free trial
- Review Information:
  - Name: "3-Day Free Trial"
  - Duration: 3 days

#### Add Subscription - Yearly:
- Product ID: `com.aydev.deenfirst.yearly`
- Name: "Yearly Premium"
- Price: $29.99
- Duration: 1 Year
- Offers: 7-day free trial
- Review Information:
  - Name: "7-Day Free Trial"
  - Duration: 7 days

---

## 📱 Testing Purchases (Sandbox)

### Enable Sandbox Testing

1. In App Store Connect, go to **Users and Access** > **Sandbox Testers**
2. Create a test account:
   - Email: (your test email)
   - Password: (your test password)
   - Region: United States

### Test on Device/Simulator

1. Run the app on a device/simulator
2. Sign in with your test Apple ID when prompted
3. Test purchase flows:
   - Subscribe to monthly (with 3-day trial)
   - Subscribe to yearly (with 7-day trial)
   - Restore purchases
   - Cancel subscription (in Settings > Apple ID > Subscriptions)

---

## 🎨 Using RevenueCat Paywalls (Optional)

RevenueCat offers pre-built paywalls. To use them:

### 1. Add Paywall Dependency

Update `Tuist/Package.swift`:
```swift
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0"),
.package(url: "https://github.com/RevenueCat/purchases-ui-ios.git", from: "5.0.0")
```

### 2. Update Project.swift

```swift
dependencies: [
    .external(name: "RevenueCat"),
    .external(name: "RevenueCatUI")
]
```

### 3. Use in PaywallView

```swift
import RevenueCatUI

struct PaywallView: View {
    var body: some View {
        PaywallView(
            offeringID: "default",
            displayCloseButton: true
        ) { purchaseResult in
            // Handle purchase completion
        }
    }
}
```

---

## 🔍 Entitlement Checking

Throughout your app, check for premium status:

```swift
// Check if user has premium access
func checkPremiumStatus() async -> Bool {
    do {
        let customerInfo = try await Purchases.shared.customerInfo()
        return customerInfo.entitlements["premium"]?.isActive == true
    } catch {
        return false
    }
}

// Or use the subscription service
let isPremium = try await subscriptionService.checkSubscriptionStatus()
```

---

## 🛡️ Best Practices

### 1. Handle Edge Cases
```swift
do {
    let isActive = try await subscriptionService.checkSubscriptionStatus()
} catch let error as SubscriptionError {
    switch error {
    case .packageNotFound(let package):
        // Show friendly error about missing package
    case .purchaseCancelled:
        // User cancelled - don't show error
    default:
        // Show generic error message
    }
}
```

### 2. Sync Local State
The app already syncs subscription status with local User entity via `SubscriptionService`.

### 3. Monitor Subscription Changes
The `SubscriptionMonitor` in `DeenFirstApp.swift` already listens to `customerInfoStream` for real-time updates.

### 4. Test in Production
For production, update the API key:
```swift
#if DEBUG
Purchases.logLevel = .debug
Purchases.configure(withAPIKey: "test_GigTjmiydMdJecOcMpeoxAtxtyi")
#else
Purchases.configure(withAPIKey: "your_production_api_key_here")
#endif
```

---

## 📊 Analytics (Optional)

RevenueCat provides automatic analytics. Enable additional tracking:

```swift
// Track custom events
Purchases.shared.track(subscriptionEvent: .trialStarted)
Purchases.shared.track(subscriptionEvent: .trialConverted)
Purchases.shared.track(subscriptionEvent: .trialCancelled)
```

---

## 📞 Support

- RevenueCat Docs: https://www.revenuecat.com/docs
- Dashboard: https://app.revenuecat.com
- iOS SDK Reference: https://www.revenuecat.com/docs/ios
