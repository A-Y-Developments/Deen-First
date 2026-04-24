---
id: 120
title: V1 core flows verified intact (negative finding)
severity: P3
area: v1-regression
status: closed
---

## Problem

N/A — this is a negative finding documenting V1 flows that were traced and confirmed working correctly after V2 changes.

## Evidence

**Auth / Sign In with Apple**
`AuthService.swift` sign-in flow, `RootView.swift` lifecycle gate — intact. `signOut()` and `deleteAccount()` both call `deleteAllRules()` with `try?` (silent swallow — minor, see finding 111 pattern). Core sign-in path unaffected.

**Emergency unblock quota + reset**
`ScreenTimeRulesService+Unblock.swift` — emergency unblock quota check, increment, and midnight reset logic present and correct. Quota stored in App Group via `AppGroupConstants` keys (no inline hardcoding in this file).

**Daily surah (Home tab)**
`HomeTabViewModel` uses deterministic seed `dayOfYear × year` for daily surah selection. V2 changes did not touch this logic. Countdown timer for unblock expiry reads from App Group correctly.

**Quran tab search**
`QuranTabViewModel` delegates search to `quranService.searchSurahs` — no regression. V2 added no new code to this tab.

**Blocking tab V1 rule listing**
Rule listing delegates to `screenTimeRulesService.rules` — the published property is updated on `objectWillChange` correctly. Lock Editing overlays are new V2 UI but do not break existing rule display.

**Settings tab**
No V2 changes to core settings (notifications, subscription, account). RevenueCat integration untouched.

**Subscription / paywall**
`PaywallView` and `SubscriptionService` — not modified in V2. `bypassPaywall` build setting correctly plumbed through `Project.swift` to `BypassPaywall` Info.plist key.

## Solution

No action required for these flows.

## Why

Documenting verified-intact flows provides a baseline for regression confidence. The V1 flows above were manually traced through ViewModel → Service → Repository and found to have no functional changes introduced by V2.
