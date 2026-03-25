# Screen Time API Implementation Guide
# Deen First

Complete reference for implementing App Limit, Time Limit (Downtime), All Day, Emergency Unblock, and Temporary Unblock features using iOS Screen Time API.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Project Setup](#project-setup)
4. [Data Models](#data-models)
5. [App Limit (Usage-Based)](#1-app-limit-usage-based)
6. [Time Limit (Schedule-Based)](#2-time-limit-schedule-based)
7. [All Day Limit](#3-all-day-limit)
8. [Temporary Unblock (Recite to Unblock)](#4-temporary-unblock)
9. [Emergency Unblock](#5-emergency-unblock)
10. [Focus Session Blocking](#6-focus-session-blocking)
11. [Extensions Configuration](#7-extensions-configuration)
12. [Key Differences Summary](#key-differences-summary)
13. [Best Practices](#best-practices)
14. [Troubleshooting](#troubleshooting)

---

## Overview

Deen First uses iOS Screen Time API (FamilyControls) with five blocking/unblocking mechanisms:

| Mechanism | Purpose | Trigger |
|-----------|---------|---------|
| **App Limit** | Restrict daily usage time | When time threshold reached |
| **Time Limit** | Block during time windows | When entering scheduled period |
| **All Day** | Block for entire days | When day becomes active |
| **Emergency Unblock** | Remove ALL blocks instantly | User action (2/week quota) |
| **Temporary Unblock** | Remove specific rule block | Successful recitation (timer-based) |
| **Focus Session** | Block during Quran listening | Session start → session end |

### Required Frameworks

```swift
import FamilyControls      // Core framework, authorization, app picker
import ManagedSettings     // Shield application
import DeviceActivity      // Usage monitoring
import Foundation
```

---

## Architecture

### Clean Architecture Layers

```
Presentation Layer
    BlockingTabView / BlockingTabViewModel
    AppLimitView / AppLimitViewModel
    TimeLimitView / TimeLimitViewModel
    EmergencyUnblockView / EmergencyUnblockViewModel
    ReciteToUnblockView / ReciteToUnblockViewModel
        ↓
Domain Layer
    ScreenTimeRulesService (protocol)
    ScreenTimeRulesServiceImpl
    ScreenTimeRulesService+Unblock (extension)
    ScreenTimeRulesService+EmergencyUnblock (extension)
        ↓
Data Layer
    ScreenTimeRulesRepository (protocol)
    ScreenTimeRulesRepositoryImpl
    → App Groups UserDefaults (shared with extensions)
    → ManagedSettingsStore
    → DeviceActivityCenter
```

### Dependency Injection

```swift
// DIContainer.swift
lazy var screenTimeRulesRepository: ScreenTimeRulesRepository =
    ScreenTimeRulesRepositoryImpl()

lazy var screenTimeRulesService: ScreenTimeRulesService =
    ScreenTimeRulesServiceImpl(repo: screenTimeRulesRepository)
```

---

## Project Setup

### Required Entitlements

**Main App** (`deenfirst.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aydev.deenfirst</string>
</array>
```

**DeviceActivityMonitor Extension** (`ScreenTimeMonitor.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aydev.deenfirst</string>
</array>
```

**Critical**: Both targets must use the **same** App Group identifier.

### App Group Shared UserDefaults

```swift
// AppGroupConstants.swift
let sharedDefaults = UserDefaults(suiteName: "group.com.aydev.deenfirst")
```

---

## Data Models

### Unified Rule Model

```swift
enum RuleType: String, Codable, Hashable {
    case timeLimit    // App Limit (usage-based)
    case timeLimit    // Time Limit (schedule-based)
    case allDay       // All Day Limit
}

struct ScreenTimeRule: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var selection: FamilyActivitySelection
    var type: RuleType

    var limitSeconds: Int?           // For timeLimit (App Limit)
    var startTime: DateComponents?   // For timeLimit (Time Limit)
    var endTime: DateComponents?     // For timeLimit
    var daysActive: Set<String>?     // For all types
    var unblockAllowedAfterLimit: Int
    var durationOptions: [Int]

    var createdAt: Date
}
```

### Configuration Models

```swift
struct AppLimitConfig: Codable {
    let id: UUID?
    let name: String
    let timeLimit: TimeLimit          // Usage quota enum
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]
}

struct TimeLimitConfig: Codable {
    let id: UUID?
    let name: String
    let startTime: DateComponents
    let endTime: DateComponents
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]
}
```

### Time Limit Enum

```swift
enum TimeLimit: Equatable, CaseIterable, Hashable, Codable {
    case fifteenMin    // 15 minutes
    case thirtyMin     // 30 minutes
    case fortyFiveMin  // 45 minutes
    case oneHour       // 1 hour
    case twoHours      // 2 hours
    case threeHours    // 3 hours
    case fourHours     // 4 hours
    case custom(Int)   // Custom seconds value

    var seconds: Int { /* switch returning seconds */ }
}
```

### UserDefaults Keys (Shared with Extensions)

```swift
enum Keys {
    static let timeLimitRules = "timeLimitRules"      // [ScreenTimeRule] - App Limits
    static let timeLimitRules = "timeLimitRules"      // [ScreenTimeRule] - Time Limits
    static let allDayRules = "allDayRules"            // [ScreenTimeRule]
    static let tokenMapping = "tokenMapping"           // [String: Data] - ApplicationToken
    static let categoryTokens = "categoryTokens"       // [String: Data] - ActivityCategoryToken
    static let emergencyUnblockExpiry = "emergencyUnblockExpiry"  // Date?
    static let emergencyUnblockWeeklyCount = "emergencyUnblockWeeklyCount"
    static let emergencyUnblockWeekStart = "emergencyUnblockWeekStart"
    // Temporary unblock: per-rule expiry stored with rule ID as key
}
```

---

## 1. App Limit (Usage-Based)

**Purpose**: Blocks apps after a daily usage quota is reached. Resets at midnight.

### Key Characteristics

| Property | Value |
|----------|-------|
| Schedule | Daily (00:00 – 23:59) |
| Trigger | When usage threshold reached |
| Event Prefix | `limitReached_app_` / `limitReached_category_` |
| Activity Name | `daily_{ruleId}` |
| Immediate Shield | No — only after threshold |
| Auto Reset | Yes, at midnight |

### Repository Implementation

```swift
func setTimeLimit(for selection: FamilyActivitySelection, config: AppLimitConfig) {
    // Load, update-or-append rule, save to UserDefaults
    // Stop old monitoring if updating existing rule

    // Create daily schedule (resets midnight)
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )

    // Create events with time threshold
    let events = ScreenTimeEvents.createEvents(
        for: .custom(config.timeLimit.seconds),
        selection: appLimits
    )

    // Start monitoring
    let name = DeviceActivityName("daily_\(ruleId.uuidString)")
    try? activityCenter.startMonitoring(name, during: schedule, events: events)
}
```

### Event Creation

```swift
// Threshold = usage time before shield applies
DeviceActivityEvent(
    applications: [token],
    threshold: DateComponents(second: limit.seconds)  // e.g., 1800 = 30 min
)
```

### Monitor Extension Handler

```swift
override func intervalDidStart(for activity: DeviceActivityName) {
    // Reset shields at midnight for new day
    if activity.rawValue.hasPrefix("daily_") {
        ManagedSettingsStore().clearAllSettings()
    }
}

override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    applyShield(for: event)  // Block the app
}
```

---

## 2. Time Limit (Schedule-Based)

**Purpose**: Blocks apps during specified time windows on selected days.

### Key Characteristics

| Property | Value |
|----------|-------|
| Schedule | Custom start/end time |
| Trigger | When entering time window |
| Event Prefix | `timeLimit_app_` / `timeLimit_category_` |
| Activity Name | `timeLimit_{ruleId}` |
| Immediate Shield | Yes — if currently in window |
| Auto Reset | No — unblocks when window ends |

### Repository Implementation

```swift
func setTimeLimitBlock(for selection: FamilyActivitySelection, config: TimeLimitConfig) {
    // Load, update-or-append rule, save

    // IMMEDIATE SHIELD if currently in window
    if config.isCurrentlyInBlockingPeriod {
        store.shield.applications = Set(selection.applicationTokens)
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    } else {
        store.shield.applications = []
        store.shield.applicationCategories = .none
    }

    // Custom time window schedule
    let schedule = DeviceActivitySchedule(
        intervalStart: config.startTime,
        intervalEnd: config.endTime,
        repeats: true
    )

    // Events with zero threshold (immediate at interval start)
    let events = ScreenTimeEvents.createTimeLimitEvents(for: appLimits)
    let name = DeviceActivityName("timeLimit_\(ruleId.uuidString)")
    try? activityCenter.startMonitoring(name, during: schedule, events: events)
}
```

### Event Creation

```swift
// Threshold = 0 (immediate when interval starts)
DeviceActivityEvent(
    applications: app.token.map { [$0] } ?? [],
    threshold: DateComponents(hour: 0, minute: 0)
)
```

### Current Period Check

```swift
extension TimeLimitConfig {
    var isCurrentlyInBlockingPeriod: Bool {
        let todayName = DayHelper.getCurrentDayName()
        guard daysActive.isEmpty || daysActive.contains(todayName) else { return false }

        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let startMinutes = (startTime.hour ?? 0) * 60 + (startTime.minute ?? 0)
        let endMinutes = (endTime.hour ?? 23) * 60 + (endTime.minute ?? 59)
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
```

---

## 3. All Day Limit

**Purpose**: Blocks apps for entire days on selected days of the week.

### Key Characteristics

| Property | Value |
|----------|-------|
| Schedule | Full day (00:00 – 23:59) |
| Trigger | When day becomes active |
| Event Prefix | `allDay_app_` / `allDay_category_` |
| Activity Name | `allDay_{ruleId}` |
| Immediate Shield | Yes — if today is in active days |
| Days | Configurable (weekdays / weekends / specific) |

### Repository Implementation

```swift
func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig) {
    // Load, update-or-append rule, save

    // IMMEDIATE SHIELD if today is an active day
    if config.shouldBlockToday {
        store.shield.applications = Set(selection.applicationTokens)
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    // Full-day schedule
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )

    let events = ScreenTimeEvents.createAllDayEvents(for: appLimits)
    let name = DeviceActivityName("allDay_\(ruleId.uuidString)")
    try? activityCenter.startMonitoring(name, during: schedule, events: events)
}
```

---

## 4. Temporary Unblock

**Purpose**: Temporarily removes blocking for a specific app/rule after successful Quran recitation.

### Implementation (ScreenTimeRulesService+Unblock)

```swift
func temporarilyUnblock(ruleId: UUID, durationMinutes: Int) {
    let expiry = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))

    // Save expiry to shared UserDefaults
    var expiryMap = sharedDefaults.dictionary(forKey: Keys.temporaryUnblockExpiry) as? [String: Date] ?? [:]
    expiryMap[ruleId.uuidString] = expiry
    sharedDefaults.set(expiryMap, forKey: Keys.temporaryUnblockExpiry)

    // Remove shield for this specific rule's apps
    guard let rule = findRule(id: ruleId) else { return }
    removeShield(for: rule)
}

func reblockExpiredTemporaryUnblocks() {
    var expiryMap = sharedDefaults.dictionary(forKey: Keys.temporaryUnblockExpiry) as? [String: Date] ?? [:]
    let now = Date()
    var changed = false

    for (ruleIdString, expiry) in expiryMap where expiry <= now {
        expiryMap.removeValue(forKey: ruleIdString)
        if let ruleId = UUID(uuidString: ruleIdString),
           let rule = findRule(id: ruleId) {
            applyShield(for: rule)
        }
        changed = true
    }

    if changed {
        sharedDefaults.set(expiryMap, forKey: Keys.temporaryUnblockExpiry)
    }
}
```

### Called From

- `RootView` on `willEnterForeground` — checks all expired temporary unblocks
- `ActiveSessionViewModel` on session end — checks expiries

---

## 5. Emergency Unblock

**Purpose**: Instantly removes ALL blocking until midnight. Weekly quota: 2 uses.

### Implementation (ScreenTimeRulesService+EmergencyUnblock)

```swift
func activateEmergencyUnblock() throws {
    // Check quota
    let weekStart = getOrCreateWeekStart()
    var weeklyCount = sharedDefaults.integer(forKey: Keys.emergencyUnblockWeeklyCount)

    guard weeklyCount < 2 else {
        throw EmergencyUnblockError.quotaExceeded
    }

    // Remove ALL shields
    let store = ManagedSettingsStore()
    store.clearAllSettings()

    // Stop all DeviceActivity monitoring temporarily
    // (monitoring resumes at midnight when emergency expires)

    // Set expiry to midnight
    let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
    sharedDefaults.set(midnight, forKey: Keys.emergencyUnblockExpiry)

    // Increment quota
    weeklyCount += 1
    sharedDefaults.set(weeklyCount, forKey: Keys.emergencyUnblockWeeklyCount)
}

func deactivateEmergencyUnblock() {
    sharedDefaults.removeObject(forKey: Keys.emergencyUnblockExpiry)
    reapplyAllActiveShields()
}

func isEmergencyUnblockActive() -> Bool {
    guard let expiry = sharedDefaults.object(forKey: Keys.emergencyUnblockExpiry) as? Date else {
        return false
    }
    return expiry > Date()
}

func remainingEmergencyUnblocks() -> Int {
    resetWeeklyCountIfNeeded()
    let used = sharedDefaults.integer(forKey: Keys.emergencyUnblockWeeklyCount)
    return max(0, 2 - used)
}

func timeUntilEmergencyUnblockExpiry() -> TimeInterval? {
    guard let expiry = sharedDefaults.object(forKey: Keys.emergencyUnblockExpiry) as? Date else {
        return nil
    }
    return max(0, expiry.timeIntervalSinceNow)
}
```

### Called From

- `EmergencyUnblockViewModel` — toggle on/off
- `RootView` on `willEnterForeground` — checks if expired, re-applies shields
- `RootView.onAppear` — initial state check

### Weekly Quota Reset

```swift
func resetWeeklyCountIfNeeded() {
    let stored = sharedDefaults.object(forKey: Keys.emergencyUnblockWeekStart) as? Date
    let monday = Calendar.current.nextDate(after: Date(),
        matching: DateComponents(weekday: 2),
        matchingPolicy: .previousTimePreservingSmallerComponents,
        direction: .backward
    ) ?? Date()

    if stored == nil || stored! < monday {
        sharedDefaults.set(monday, forKey: Keys.emergencyUnblockWeekStart)
        sharedDefaults.set(0, forKey: Keys.emergencyUnblockWeeklyCount)
    }
}
```

---

## 6. Focus Session Blocking

**Purpose**: Directly blocks selected apps during an active Quran listening session (not via DeviceActivity).

### Implementation

```swift
// Session start: apply shield directly
func startSessionBlock(for selection: FamilyActivitySelection) {
    let store = ManagedSettingsStore()
    store.shield.applications = selection.applicationTokens
    if !selection.categoryTokens.isEmpty {
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
}

// Session end: remove session shield, reapply persistent rules
func endSessionBlock() {
    reapplyActiveShields()  // Reapply all persistent rules (removes session-only shield if no persistent rules)
}
```

**Key difference from other types**: No DeviceActivity monitoring. Direct ManagedSettingsStore manipulation. Shield is removed when session ends regardless of time.

---

## 7. Extensions Configuration

### DeviceActivityMonitorExtension

```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Reset App Limit shields at midnight
        if activity.rawValue.hasPrefix("daily_") {
            ManagedSettingsStore().clearAllSettings()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        ManagedSettingsStore().clearAllSettings()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield(for: event)
    }

    private func applyShield(for event: DeviceActivityEvent.Name) {
        let store = ManagedSettingsStore()
        let raw = event.rawValue
        guard let defaults = UserDefaults(suiteName: "group.com.aydev.deenfirst") else { return }

        // Route to correct shield application based on event prefix
        if raw.hasPrefix("limitReached_app_") {
            applyAppShield(uuid: raw.replacingOccurrences(of: "limitReached_app_", with: ""), store: store, defaults: defaults)
        } else if raw.hasPrefix("limitReached_category_") {
            applyCategoryShield(uuid: raw.replacingOccurrences(of: "limitReached_category_", with: ""), store: store, defaults: defaults)
        } else if raw.hasPrefix("timeLimit_app_") {
            applyAppShield(uuid: raw.replacingOccurrences(of: "timeLimit_app_", with: ""), store: store, defaults: defaults)
        } else if raw.hasPrefix("timeLimit_category_") {
            applyCategoryShield(uuid: raw.replacingOccurrences(of: "timeLimit_category_", with: ""), store: store, defaults: defaults)
        } else if raw.hasPrefix("allDay_app_") {
            applyAppShield(uuid: raw.replacingOccurrences(of: "allDay_app_", with: ""), store: store, defaults: defaults)
        } else if raw.hasPrefix("allDay_category_") {
            applyCategoryShield(uuid: raw.replacingOccurrences(of: "allDay_category_", with: ""), store: store, defaults: defaults)
        }
    }
}
```

### ShieldConfigurationExtension

```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            icon: UIImage(named: "shield-icon") ?? UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(text: "Deen First", color: .label),
            subtitle: ShieldConfiguration.Label(text: "Time to read Quran instead 🌙", color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .white),
            primaryButtonBackgroundColor: UIColor(hex: "#5C64D0")
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }
}
```

---

## Key Differences Summary

| Feature | App Limit | Time Limit | All Day | Emergency | Temporary | Focus Session |
|---------|-----------|------------|---------|-----------|-----------|--------------|
| Schedule | Daily 00-24 | Custom start/end | Daily 00-24 | None | None | None |
| Trigger | Threshold reached | Interval start | Interval start | Manual | Recitation | Session start |
| Immediate shield | No | Yes (if in window) | Yes (if today) | Yes | Removes shield | Yes |
| Auto reset | Midnight | Interval end | Midnight | No (midnight expiry) | Timer | Session end |
| DeviceActivity | Yes | Yes | Yes | No | No | No |
| ManagedSettings | Via extension | Via extension | Via extension | Direct | Direct | Direct |

---

## Best Practices

### 1. Token Persistence

Always store ApplicationToken and ActivityCategoryToken in shared UserDefaults — extensions cannot access them otherwise:

```swift
private static func saveTokenMapping(uuid: UUID, token: ApplicationToken) {
    guard let defaults = UserDefaults(suiteName: "group.com.aydev.deenfirst") else { return }
    var dict = defaults.dictionary(forKey: "tokenMapping") as? [String: Data] ?? [:]
    if let data = try? JSONEncoder().encode(token) {
        dict[uuid.uuidString] = data
        defaults.set(dict, forKey: "tokenMapping")
    }
}
```

### 2. Shield Reapplication

When deleting a rule or after temporary unblock expires, reapply shields for all remaining active rules:

```swift
func reapplyActiveShields() {
    let store = ManagedSettingsStore()
    store.clearAllSettings()

    // Check emergency unblock first — if active, don't reapply
    if isEmergencyUnblockActive() { return }

    // Reapply Time Limit rules (if currently in window)
    // Reapply All Day rules (if today is active)
    // App Limit rules are handled by DeviceActivity extension (don't reapply here)
    // Temporary unblocks: skip rules that have active temporary unblock
}
```

### 3. Day Helper

```swift
enum DayHelper {
    static let allDayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    static func getCurrentDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
}
```

### 4. Subscription Expiry Shield Removal

When subscription expires, remove everything:

```swift
func removeAllShields() {
    let store = ManagedSettingsStore()
    store.clearAllSettings()

    let center = DeviceActivityCenter()
    // Stop all monitoring — subscription required for blocking features
    for activity in center.activities {
        center.stopMonitoring([activity])
    }

    // Clear all expiry timestamps
    sharedDefaults.removeObject(forKey: Keys.emergencyUnblockExpiry)
    sharedDefaults.removeObject(forKey: Keys.temporaryUnblockExpiry)
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| Shield doesn't appear | Verify App Group ID matches in both entitlements; check FamilyControls authorization status |
| Time Limits not resetting | Verify `intervalDidStart` is called; check activity name starts with `daily_`; schedule must have `repeats: true` |
| Immediate shields not working | Check `isCurrentlyInBlockingPeriod` / `shouldBlockToday` logic; verify `ManagedSettingsStore` called synchronously |
| Extension not receiving events | Check monitor extension entitlements include app group; verify events are created with correct naming |
| Emergency unblock not clearing | Call `store.clearAllSettings()` explicitly; if shields persist, restart device (known iOS bug) |
| Temporary unblock not re-blocking | Check `reblockExpiredTemporaryUnblocks()` is called on foreground; verify expiry timestamps are saved correctly |
| Screen Time works on device not simulator | Expected — Screen Time API requires physical device (iOS 17+) |

---

## Quick Reference

### Event Naming

| Type | App Event | Category Event |
|------|-----------|----------------|
| App Limit | `limitReached_app_{uuid}` | `limitReached_category_{uuid}` |
| Time Limit | `timeLimit_app_{uuid}` | `timeLimit_category_{uuid}` |
| All Day | `allDay_app_{uuid}` | `allDay_category_{uuid}` |

### Activity Names

| Type | Format |
|------|--------|
| App Limit | `daily_{ruleId}` |
| Time Limit | `timeLimit_{ruleId}` |
| All Day | `allDay_{ruleId}` |

### File Structure

```
deenfirst/Sources/
├── Domain/Services/
│   ├── ScreenTimeRulesService.swift
│   ├── ScreenTimeRulesService+Unblock.swift
│   └── ScreenTimeRulesService+EmergencyUnblock.swift
├── Data/Repositories/
│   └── ScreenTimeRulesRepository.swift
├── Shared/
│   ├── AppGroupConstants.swift
│   ├── DayHelper.swift
│   └── ScreenTimeEvents.swift
└── Utils/
    ├── DeviceActivityScheduleHelper.swift
    └── TimeLimitHelper.swift

ScreenTimeMonitor/
└── DeviceActivityMonitorExtension.swift

Shield/
└── ShieldConfigurationExtension.swift
```
