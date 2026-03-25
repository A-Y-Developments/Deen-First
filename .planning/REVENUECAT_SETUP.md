# RevenueCat Integration Guide - Deen First

## Overview

This guide covers the complete RevenueCat integration for Deen First. RevenueCat manages subscription state, purchase flows, and restore purchases. The app checks subscription status on every launch and foreground event to gate access and manage Screen Time shields.

---

## ✅ Already Implemented

### 1. SDK Installation

RevenueCat installed via Tuist in `Tuist/Package.swift`:
```
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.57.0")
```

### 2. Configuration

RevenueCat is initialized in `Sources/DeenFirstApp.swift`.

**Important**: Use environment-specific API keys:
```swift
#if DEBUG
Purchases.logLevel = .debug
Purchases.configure(withAPIKey: "your_test_api_key_here")
#else
Purchases.configure(withAPIKey: "your_production_api_key_here")
#endif
```

Do **not** commit API keys to source control. Store them in `.env` or a secrets manager.

### 3. Core Services

- `SubscriptionService` protocol with full `async/await` support
- `SubscriptionServiceImpl` — purchase, restore, entitlement checking, expiry handling
- `PaywallViewModel` — subscription UI state
- `PaywallView` — custom paywall UI (yearly default, monthly option)
- `SubscriptionView` / `SubscriptionPlansView` — in-app subscription management (Settings tab)

### 4. Subscription Monitoring

`SubscriptionMonitor` class in `DeenFirstApp.swift` listens to RevenueCat's `customerInfoStream` for real-time subscription changes. On expiry:
1. All Screen Time shields removed
2. Paywall shown to user

---

## 🔧 RevenueCat Dashboard Setup

### Step 1: Configure Products

Go to [app.revenuecat.com](https://app.revenuecat.com) → **Products** → **iOS**

**Monthly Product:**
- Product ID: `com.aydev.deenfirst.monthly`
- Display Name: Deen First Monthly
- Price: $4.99/month
- Trial: 3 days

**Yearly Product:**
- Product ID: `com.aydev.deenfirst.yearly`
- Display Name: Deen First Yearly
- Price: $29.99/year
- Trial: 7 days

### Step 2: Create Offering

Navigate to **Offerings** → create offering named **"default"**

Add packages:
- Monthly package → `com.aydev.deenfirst.monthly`
- Annual package → `com.aydev.deenfirst.yearly`

### Step 3: Create Entitlement

Navigate to **Entitlements** → create entitlement: **"premium"**

Attach both products to this entitlement.

### Step 4: Configure App Store Connect

Go to [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **Deen First** → **Subscriptions** → **Create Subscription Group** ("Deen First Premium")

**Monthly:**
- Product ID: `com.aydev.deenfirst.monthly`
- Name: Monthly Premium
- Price: $4.99
- Duration: 1 Month
- Offer: 3-day free trial

**Yearly:**
- Product ID: `com.aydev.deenfirst.yearly`
- Name: Yearly Premium
- Price: $29.99
- Duration: 1 Year
- Offer: 7-day free trial

---

## 📱 Testing Purchases (Sandbox)

### Setup Sandbox Tester

In App Store Connect → **Users and Access** → **Sandbox Testers** → create test account with US region.

### Test Flows

1. **Subscribe monthly** (3-day trial) → verify access granted, Screen Time active
2. **Subscribe yearly** (7-day trial) → verify access granted, Screen Time active
3. **Restore purchases** → verify access restored
4. **Cancel subscription** (Settings → Apple ID → Subscriptions) → verify shields removed on next launch
5. **Expiry mid-session** — advance sandbox clock, verify session completes before paywall shows

---

## 🔍 Entitlement Checking

The app checks entitlement in multiple places:

- **On launch** (RootView): gates access to main tabs
- **On foreground** (NotificationCenter): re-checks after backgrounding
- **On session end** (focus sessions): checks if subscription lapsed mid-session
- **SubscriptionMonitor stream**: real-time updates without polling

Entitlement check:
```swift
let customerInfo = try await Purchases.shared.customerInfo()
let isPremium = customerInfo.entitlements["premium"]?.isActive == true
```

When `isPremium = false`:
1. `screenTimeService.removeAllShields()` — clears all blocking
2. Navigate to `.paywall`

---

## 🛡️ Edge Cases

| Scenario | Behavior |
|----------|---------|
| Subscription expires mid listening session | Session completes → expiry handled on end |
| User cancels and reinstalls | Restore Purchases flow |
| Subscription restores on old device | RevenueCat syncs across Apple ID |
| Trial ends without payment | Treated same as expired subscription |
| Network unavailable at launch | Falls back to cached customerInfo |

---

## 📊 Bundle IDs Reference

| Product | ID |
|---------|-----|
| Monthly | `com.aydev.deenfirst.monthly` |
| Yearly | `com.aydev.deenfirst.yearly` |
| Entitlement | `premium` |
| RevenueCat Offering | `default` |

---

## 📞 Support

- RevenueCat Docs: https://www.revenuecat.com/docs
- Dashboard: https://app.revenuecat.com
- iOS SDK Reference: https://www.revenuecat.com/docs/ios
