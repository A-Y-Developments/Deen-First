# Screen Time API Implementation Guide

Complete guide for implementing **App Limit**, **Downtime (Time of Day)**, and **All Day Limit** features using iOS Screen Time API with custom shields.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Project Setup](#project-setup)
4. [Core Components](#core-components)
5. [Data Models](#data-models)
6. [App Limit Implementation](#1-app-limit-time-limit)
7. [Downtime Implementation](#2-downtime-time-of-day)
8. [All Day Limit Implementation](#3-all-day-limit)
9. [Key Differences Summary](#key-differences-summary)
10. [Extensions Configuration](#extensions-configuration)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)
13. [Quick Reference](#quick-reference)

---

## Overview

This guide covers implementing Apple's Screen Time API with **three types of blocking**:

| Block Type | Purpose | Trigger |
|------------|---------|---------|
| **App Limit** | Restricts usage time | When time threshold reached |
| **Downtime** | Blocks during time windows | When entering scheduled period |
| **All Day** | Blocks for entire days | When day becomes active |

### Required Frameworks

```swift
import FamilyControls      // Core framework for Screen Time
import ManagedSettings     // For applying shields/blocks
import DeviceActivity      // For monitoring usage
import Foundation          // Standard library
```

---

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ BlockingView │  │AppLimitSheet │  │DowntimeSheet │  │
│  │              │  │              │  │              │  │
│  │   ViewModel  │  │   ViewModel  │  │   ViewModel  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┼──────────────────┼──────────────────┼─────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────┐
│         ▼                  ▼                  ▼         │
│              Domain Layer                          │
│  ┌──────────────────────────────────────────────┐     │
│  │         ScreenTimeUseCase (Protocol)         │     │
│  │  ┌────────────────────────────────────────┐  │     │
│  │  │     ScreenTimeUseCaseImpl             │  │     │
│  │  └────────────────────────────────────────┘  │     │
│  └───────────────────┬──────────────────────────┘     │
└──────────────────────┼────────────────────────────────┘
                       │
┌──────────────────────┼────────────────────────────────┐
│                      ▼                                 │
│                 Data Layer                             │
│  ┌──────────────────────────────────────────────┐     │
│  │      ScreenTimeRepository (Protocol)         │     │
│  │  ┌────────────────────────────────────────┐  │     │
│  │  │   ScreenTimeRepositoryImpl             │  │     │
│  │  │  - AuthorizationCenter                 │  │     │
│  │  │  - ManagedSettingsStore                │  │     │
│  │  │  - DeviceActivityCenter                │  │     │
│  │  │  - UserDefaults (App Group)            │  │     │
│  │  └────────────────────────────────────────┘  │     │
│  └──────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────┘
```

### Dependency Injection

```swift
// DIContainer.swift
class DIContainer {
    static let shared = DIContainer()

    lazy var screenTimeRepository: ScreenTimeRepository = ScreenTimeRepositoryImpl()
    lazy var screenTimeUsecase: ScreenTimeUseCase = ScreenTimeUseCaseImpl(
        screenTimeRepository: screenTimeRepository
    )

    private init() {}
}
```

---

## Project Setup

### 1. Enable Capabilities

**Main App Target** (`mindcore.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourapp.screentime</string>
</array>
```

### 2. Create Extensions

You need **separate targets** for:

1. **DeviceActivityMonitorExtension** - Background monitoring
2. **ShieldConfigurationExtension** - Custom shield UI

### 3. App Group Configuration

**All targets must share the same app group:**

```swift
let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.screentime")
```

---

## Core Components

### Repository Protocol

```swift
protocol ScreenTimeRepository {
    func requestAuthorization() async -> Bool
    func setTimeLimit(for selection: FamilyActivitySelection, config: TimeLimitConfig)
    func setTimeOfDayBlock(for selection: FamilyActivitySelection, config: TimeOfDayConfig)
    func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig)
    func deleteTimeLimit(id: UUID)
    func deleteTimeOfDay(id: UUID)
    func deleteAllDay(id: UUID)
}
```

### Use Case Protocol

```swift
protocol ScreenTimeUseCase {
    func requestAuthorization() async -> Bool
    func setTimeLimit(for selection: FamilyActivitySelection, config: TimeLimitConfig)
    func setTimeOfDayBlock(for selection: FamilyActivitySelection, config: TimeOfDayConfig)
    func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig)
    func deleteTimeLimit(id: UUID)
    func deleteTimeOfDay(id: UUID)
    func deleteAllDay(id: UUID)
}
```

---

## Data Models

### Unified Rule Model

All three block types share a **unified model**:

```swift
enum RuleType: String, Codable, Hashable {
    case timeLimit    // App Limit
    case timeOfDay    // Downtime
    case allDay       // All Day Limit
}

struct ScreenTimeRule: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var selection: FamilyActivitySelection
    var type: RuleType

    // Optional fields based on type
    var limitSeconds: Int?           // For timeLimit
    var startTime: DateComponents?   // For timeOfDay
    var endTime: DateComponents?     // For timeOfDay
    var daysActive: Set<String>?     // For all types
    var unblockAllowedAfterLimit: Int?
    var durationOptions: [Int]?

    var createdAt: Date
}
```

### Configuration Models

#### Time Limit Config (App Limit)
```swift
struct TimeLimitConfig: Codable {
    let id: UUID?
    let name: String
    let timeLimit: TimeLimit          // The duration enum
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]
}
```

#### Time of Day Config (Downtime)
```swift
struct TimeOfDayConfig: Codable {
    let id: UUID?
    let name: String
    let startTime: DateComponents
    let endTime: DateComponents
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]

    var isCurrentlyInBlockingPeriod: Bool {
        // Check if today is active and within time window
    }
}
```

#### All Day Config
```swift
struct AllDayConfig: Codable {
    let id: UUID?
    let name: String
    let daysActive: Set<String>
    let unblockAllowedAfterLimit: Int
    let durationOptions: [Int]

    var shouldBlockToday: Bool {
        // Check if today is in active days
    }
}
```

### Time Limit Enum

```swift
enum TimeLimit: Equatable, CaseIterable, Hashable, Codable {
    case fifteenMin
    case thirtyMin
    case fortyFiveMin
    case oneHour
    case twoHours
    case threeHours
    case fourHours
    case custom(Int)

    var seconds: Int {
        switch self {
        case .fifteenMin: return 15 * 60
        case .thirtyMin: return 30 * 60
        case .fortyFiveMin: return 45 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .custom(let value): return value
        }
    }
}
```

### UserDefaults Keys Pattern

```swift
private enum Keys {
    static let timeLimitRules = "timeLimitRules"
    static let timeOfDayRules = "timeOfDayRules"
    static let allDayRules = "allDayRules"
    static let tokenMapping = "tokenMapping"           // ApplicationToken storage
    static let categoryTokens = "categoryTokens"        // ActivityCategoryToken storage
}
```

---

## 1. App Limit (Time Limit)

### Purpose
Restricts usage time for selected apps/categories. Blocks when time threshold is reached.

### Key Characteristics
| Property | Value |
|----------|-------|
| **Schedule** | Daily (00:00 - 23:59) |
| **Trigger** | When time threshold reached |
| **Event Prefix** | `limitReached_app_` / `limitReached_category_` |
| **Activity Name** | `daily_{ruleId}` |
| **Threshold** | Configurable (15min to 4+ hours) |
| **Auto Reset** | Yes, at midnight |
| **Immediate Shield** | **No** - only after threshold |

### Repository Implementation

```swift
func setTimeLimit(for selection: FamilyActivitySelection, config: TimeLimitConfig) {
    var rules = load(Keys.timeLimitRules, as: [ScreenTimeRule].self) ?? []
    let ruleId: UUID
    let createdAt: Date

    // Handle update vs create
    if let id = config.id, let index = rules.firstIndex(where: { $0.id == id }) {
        ruleId = id
        createdAt = rules[index].createdAt

        // Stop old monitoring
        let oldName = DeviceActivityName("daily_\(id.uuidString)")
        try? activityCenter.stopMonitoring([oldName])

        // Update existing rule
        rules[index] = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeLimit,
            limitSeconds: config.timeLimit.seconds,
            startTime: nil,
            endTime: nil,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        )
    } else {
        // Create new rule
        ruleId = config.id ?? UUID()
        createdAt = Date()

        rules.append(ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeLimit,
            limitSeconds: config.timeLimit.seconds,
            startTime: nil,
            endTime: nil,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        ))
    }

    save(rules, to: Keys.timeLimitRules)

    // Build AppLimit array for events
    var appLimits: [AppLimit] = []
    appLimits += selection.applicationTokens.map {
        AppLimit(id: UUID(), token: $0, categoryToken: nil)
    }
    appLimits += selection.categoryTokens.map {
        AppLimit(id: UUID(), token: nil, categoryToken: $0)
    }

    // Create daily schedule (resets at midnight)
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

func deleteTimeLimit(id: UUID) {
    var rules = load(Keys.timeLimitRules, as: [ScreenTimeRule].self) ?? []
    rules.removeAll { $0.id == id }
    save(rules, to: Keys.timeLimitRules)

    let name = DeviceActivityName("daily_\(id.uuidString)")
    try? activityCenter.stopMonitoring([name])

    reapplyActiveShields()
}
```

### Event Creation (Time Limit)

```swift
static func createEvents(for limit: TimeLimit, selection: [AppLimit]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

    for app in selection {
        // Handle individual apps
        if let token = app.token {
            let eventName = DeviceActivityEvent.Name("limitReached_app_\(app.id.uuidString)")
            events[eventName] = DeviceActivityEvent(
                applications: [token],
                categories: [],
                webDomains: [],
                threshold: DateComponents(second: limit.seconds)  // KEY: Time threshold
            )
            saveTokenMapping(uuid: app.id, token: token)
        }

        // Handle categories
        if let categoryToken = app.categoryToken {
            let eventName = DeviceActivityEvent.Name("limitReached_category_\(app.id.uuidString)")
            events[eventName] = DeviceActivityEvent(
                applications: [],
                categories: [categoryToken],
                webDomains: [],
                threshold: DateComponents(second: limit.seconds)
            )
            saveCategoryToken(uuid: app.id, token: categoryToken)
        }
    }
    return events
}
```

### Monitor Extension (Time Limit)

```swift
override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    // Reset at midnight for daily schedules
    if activity.rawValue.hasPrefix("daily_") {
        let store = ManagedSettingsStore()
        store.clearAllSettings()
        print("Reset limits for new day: \(activity.rawValue)")
    }
}

override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    applyShield(for: event)
}
```

---

## 2. Downtime (Time of Day)

### Purpose
Blocks apps during specific time windows on selected days.

### Key Characteristics
| Property | Value |
|----------|-------|
| **Schedule** | Custom start/end time |
| **Trigger** | When entering time window |
| **Event Prefix** | `timeOfDay_app_` / `timeOfDay_category_` |
| **Activity Name** | `timeOfDay_{ruleId}` |
| **Threshold** | Immediate (0 seconds) |
| **Days** | Configurable |
| **Immediate Shield** | **Yes** - if currently in window |

### Repository Implementation

```swift
func setTimeOfDayBlock(for selection: FamilyActivitySelection, config: TimeOfDayConfig) {
    var rules = load(Keys.timeOfDayRules, as: [ScreenTimeRule].self) ?? []
    let ruleId: UUID
    let createdAt: Date

    // Handle update vs create (same pattern as Time Limit)
    if let id = config.id, let index = rules.firstIndex(where: { $0.id == id }) {
        ruleId = id
        createdAt = rules[index].createdAt
        let oldName = DeviceActivityName("timeOfDay_\(id.uuidString)")
        try? activityCenter.stopMonitoring([oldName])

        rules[index] = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeOfDay,
            limitSeconds: nil,
            startTime: config.startTime,
            endTime: config.endTime,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        )
    } else {
        ruleId = config.id ?? UUID()
        createdAt = Date()

        rules.append(ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .timeOfDay,
            limitSeconds: nil,
            startTime: config.startTime,
            endTime: config.endTime,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        ))
    }

    save(rules, to: Keys.timeOfDayRules)

    // Build AppLimit array
    var appLimits: [AppLimit] = []
    appLimits += selection.applicationTokens.map {
        AppLimit(id: UUID(), token: $0, categoryToken: nil)
    }
    appLimits += selection.categoryTokens.map {
        AppLimit(id: UUID(), token: nil, categoryToken: $0)
    }

    // IMMEDIATE SHIELD APPLICATION - Key difference from Time Limit
    if config.isCurrentlyInBlockingPeriod {
        store.shield.applications = Set(selection.applicationTokens)
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
    } else {
        store.shield.applications = []
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
    }

    // Create schedule with custom time window
    let schedule = DeviceActivitySchedule(
        intervalStart: config.startTime,  // KEY: Custom start time
        intervalEnd: config.endTime,      // KEY: Custom end time
        repeats: true
    )

    // Create events with zero threshold (immediate)
    let events = ScreenTimeEvents.createTimeOfDayEvents(for: appLimits)

    // Start monitoring
    let name = DeviceActivityName("timeOfDay_\(ruleId.uuidString)")
    try? activityCenter.startMonitoring(name, during: schedule, events: events)
}
```

### Event Creation (Time of Day)

```swift
static func createTimeOfDayEvents(for selection: [AppLimit]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

    for app in selection {
        let eventName = DeviceActivityEvent.Name("timeOfDay_app_\(app.id.uuidString)")
        events[eventName] = DeviceActivityEvent(
            applications: app.token.map { [$0] } ?? [],
            categories: app.categoryToken != nil ? [app.categoryToken!] : [],
            webDomains: [],
            threshold: DateComponents(hour: 0, minute: 0)  // KEY: Zero threshold = immediate
        )

        if let token = app.token {
            saveTokenMapping(uuid: app.id, token: token)
        }
        if let categoryToken = app.categoryToken {
            saveCategoryToken(uuid: app.id, token: categoryToken)
        }
    }
    return events
}
```

### Time Window Validation

```swift
extension TimeOfDayConfig {
    var isCurrentlyInBlockingPeriod: Bool {
        // First check if today is an active day
        let todayName = DayHelper.getCurrentDayName()
        guard daysActive.isEmpty || daysActive.contains(todayName) else {
            return false
        }

        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentHour = now.hour ?? 0
        let currentMinute = now.minute ?? 0
        let startHour = startTime.hour ?? 0
        let startMinute = startTime.minute ?? 0
        let endHour = endTime.hour ?? 23
        let endMinute = endTime.minute ?? 59

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
```

---

## 3. All Day Limit

### Purpose
Blocks apps for entire day(s) on selected days of the week.

### Key Characteristics
| Property | Value |
|----------|-------|
| **Schedule** | Full day (00:00 - 23:59) |
| **Trigger** | When day becomes active |
| **Event Prefix** | `allDay_app_` / `allDay_category_` |
| **Activity Name** | `allDay_{ruleId}` |
| **Threshold** | Immediate (0 seconds) |
| **Days** | Configurable |
| **Immediate Shield** | **Yes** - if today is active |

### Repository Implementation

```swift
func setAllDayBlock(for selection: FamilyActivitySelection, config: AllDayConfig) {
    var rules = load(Keys.allDayRules, as: [ScreenTimeRule].self) ?? []
    let ruleId: UUID
    let createdAt: Date

    // Handle update vs create (same pattern)
    if let id = config.id, let index = rules.firstIndex(where: { $0.id == id }) {
        ruleId = id
        createdAt = rules[index].createdAt
        let oldName = DeviceActivityName("allDay_\(id.uuidString)")
        try? activityCenter.stopMonitoring([oldName])

        rules[index] = ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .allDay,
            limitSeconds: nil,
            startTime: nil,
            endTime: nil,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        )
    } else {
        ruleId = config.id ?? UUID()
        createdAt = Date()

        rules.append(ScreenTimeRule(
            id: ruleId,
            name: config.name,
            selection: selection,
            type: .allDay,
            limitSeconds: nil,
            startTime: nil,
            endTime: nil,
            daysActive: config.daysActive,
            unblockAllowedAfterLimit: config.unblockAllowedAfterLimit,
            durationOptions: config.durationOptions,
            createdAt: createdAt
        ))
    }

    save(rules, to: Keys.allDayRules)

    // Build AppLimit array
    var appLimits: [AppLimit] = []
    appLimits += selection.applicationTokens.map {
        AppLimit(id: UUID(), token: $0, categoryToken: nil)
    }
    appLimits += selection.categoryTokens.map {
        AppLimit(id: UUID(), token: nil, categoryToken: $0)
    }

    // IMMEDIATE SHIELD APPLICATION - Key difference
    if config.shouldBlockToday {
        store.shield.applications = Set(selection.applicationTokens)
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(selection.categoryTokens)
    } else {
        store.shield.applications = []
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
    }

    // Create full-day schedule
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )

    // Create events
    let events = ScreenTimeEvents.createAllDayEvents(for: appLimits)

    // Start monitoring
    let name = DeviceActivityName("allDay_\(ruleId.uuidString)")
    try? activityCenter.startMonitoring(name, during: schedule, events: events)
}
```

### Event Creation (All Day)

```swift
static func createAllDayEvents(for selection: [AppLimit]) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

    for app in selection {
        let eventName = DeviceActivityEvent.Name("allDay_app_\(app.id.uuidString)")
        events[eventName] = DeviceActivityEvent(
            applications: app.token.map { [$0] } ?? [],
            categories: app.categoryToken != nil ? [app.categoryToken!] : [],
            webDomains: [],
            threshold: DateComponents(hour: 0, minute: 0)  // KEY: Zero threshold
        )

        if let token = app.token {
            saveTokenMapping(uuid: app.id, token: token)
        }
        if let categoryToken = app.categoryToken {
            saveCategoryToken(uuid: app.id, token: categoryToken)
        }
    }
    return events
}
```

### Day Validation

```swift
extension AllDayConfig {
    var shouldBlockToday: Bool {
        let todayName = DayHelper.getCurrentDayName()
        return daysActive.isEmpty || daysActive.contains(todayName)
    }
}
```

---

## Key Differences Summary

### Comparison Table

| Feature | App Limit | Downtime | All Day |
|---------|-----------|----------|---------|
| **Purpose** | Time-based quota | Schedule-based blocking | Day-based blocking |
| **Schedule** | 00:00-23:59 (daily) | Custom start/end | 00:00-23:59 (selected days) |
| **Threshold** | Configurable seconds | 0 (immediate) | 0 (immediate) |
| **Event Prefix** | `limitReached_` | `timeOfDay_` | `allDay_` |
| **Activity Name** | `daily_{id}` | `timeOfDay_{id}` | `allDay_{id}` |
| **Immediate Shield** | No (after threshold) | Yes (if in window) | Yes (if today active) |
| **Auto Reset** | Yes (midnight) | No | No |
| **Days Active** | Optional | Required | Required |

### Shield Application Patterns

```swift
// App Limit: Shield applied ONLY when threshold reached
// No immediate shield on creation

// Downtime: Shield applied IMMEDIATELY if in time window
if config.isCurrentlyInBlockingPeriod {
    store.shield.applications = Set(selection.applicationTokens)
}

// All Day: Shield applied IMMEDIATELY if today is active
if config.shouldBlockToday {
    store.shield.applications = Set(selection.applicationTokens)
}
```

### Event Threshold Patterns

```swift
// App Limit: Time-based threshold
threshold: DateComponents(second: limit.seconds)

// Downtime: Immediate (zero) threshold
threshold: DateComponents(hour: 0, minute: 0)

// All Day: Immediate (zero) threshold
threshold: DateComponents(hour: 0, minute: 0)
```

---

## Extensions Configuration

### 1. DeviceActivityMonitorExtension

**Purpose**: Background monitoring that triggers shields when thresholds are reached.

**File**: `DeviceActivityMonitorExtension.swift`

```swift
import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // For time-limit schedules we name them as "daily_<ruleId>"
        if activity.rawValue.hasPrefix("daily_") {
            let store = ManagedSettingsStore()
            store.clearAllSettings()
            print("Reset limits for new day interval: \(activity.rawValue)")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let store = ManagedSettingsStore()
        store.clearAllSettings()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield(for: event)
    }

    private func applyShield(for event: DeviceActivityEvent.Name) {
        let store = ManagedSettingsStore()
        let raw = event.rawValue

        guard let defaults = UserDefaults(suiteName: "group.com.yourapp.screentime") else { return }

        // Helper closures
        func applyApp(by uuidString: String) {
            guard
                let dict = defaults.dictionary(forKey: "tokenMapping") as? [String: Data],
                let data = dict[uuidString],
                let token = try? JSONDecoder().decode(ApplicationToken.self, from: data)
            else { return }
            store.shield.applications = (store.shield.applications ?? []).union([token])
        }

        func applyCategory(by uuidString: String) {
            guard
                let dict = defaults.dictionary(forKey: "categoryTokens") as? [String: Data],
                let data = dict[uuidString],
                let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
            else { return }

            if let existing = store.shield.applicationCategories {
                switch existing {
                case .all:
                    store.shield.applicationCategories = .all()
                case .specific(let categories, let exceptApps):
                    var newCategories = categories
                    newCategories.insert(token)
                    store.shield.applicationCategories = .specific(newCategories, except: exceptApps)
                case .none:
                    break
                @unknown default:
                    break
                }
            } else {
                store.shield.applicationCategories = .specific([token], except: [])
            }
        }

        // Time limit events
        if raw.hasPrefix("limitReached_app_") {
            applyApp(by: raw.replacingOccurrences(of: "limitReached_app_", with: ""))
            return
        }
        if raw.hasPrefix("limitReached_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "limitReached_category_", with: ""))
            return
        }

        // Time-of-day events
        if raw.hasPrefix("timeOfDay_app_") {
            applyApp(by: raw.replacingOccurrences(of: "timeOfDay_app_", with: ""))
            return
        }
        if raw.hasPrefix("timeOfDay_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "timeOfDay_category_", with: ""))
            return
        }

        // All-day events
        if raw.hasPrefix("allDay_app_") {
            applyApp(by: raw.replacingOccurrences(of: "allDay_app_", with: ""))
            return
        }
        if raw.hasPrefix("allDay_category_") {
            applyCategory(by: raw.replacingOccurrences(of: "allDay_category_", with: ""))
            return
        }
    }
}
```

**Entitlements** (`ScreenTimeMonitor.entitlements`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourapp.screentime</string>
</array>
```

### 2. ShieldConfigurationExtension

**Purpose**: Custom UI shown when apps are blocked.

**File**: `ShieldConfigurationExtension.swift`

```swift
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    let title = "Your App Name"
    let body = "You have restricted usage of this application."

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let icon = UIImage(named: "shield-icon") ?? UIImage(systemName: "shield.fill")
        return ShieldConfiguration(
            icon: icon,
            title: ShieldConfiguration.Label(text: title, color: UIColor.label),
            subtitle: ShieldConfiguration.Label(text: body, color: UIColor.label),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: UIColor.white),
            primaryButtonBackgroundColor: UIColor(yourBrandColor),
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return configuration(shielding: Application(""))
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
```

**Entitlements** (`shield.entitlements`):
```xml
<!-- Empty or minimal entitlements -->
```

---

## Best Practices

### 1. Token Persistence

Always store tokens in shared UserDefaults for extension access:

```swift
private static func saveTokenMapping(uuid: UUID, token: ApplicationToken) {
    guard let defaults = UserDefaults(suiteName: "group.com.yourapp.screentime") else { return }
    var dict = defaults.dictionary(forKey: "tokenMapping") as? [String: Data] ?? [:]
    if let data = try? JSONEncoder().encode(token) {
        dict[uuid.uuidString] = data
        defaults.set(dict, forKey: "tokenMapping")
    }
}

private static func saveCategoryToken(uuid: UUID, token: ActivityCategoryToken) {
    guard let defaults = UserDefaults(suiteName: "group.com.yourapp.screentime") else { return }
    var dict = defaults.dictionary(forKey: "categoryTokens") as? [String: Data] ?? [:]
    if let data = try? JSONEncoder().encode(token) {
        dict[uuid.uuidString] = data
        defaults.set(dict, forKey: "categoryTokens")
    }
}
```

### 2. Shield Reapplication

When deleting rules, reapply shields for remaining active rules:

```swift
private func reapplyActiveShields() {
    let store = ManagedSettingsStore()
    store.clearAllSettings()

    let remainingTimeOfDay: [ScreenTimeRule] = load(Keys.timeOfDayRules, as: [ScreenTimeRule].self) ?? []
    let remainingAllDay: [ScreenTimeRule] = load(Keys.allDayRules, as: [ScreenTimeRule].self) ?? []

    var applicationTokens: Set<ApplicationToken> = []
    var categoryTokens: Set<ActivityCategoryToken> = []

    let todayName = DayHelper.getCurrentDayName()
    let calendar = Calendar.current
    let now = Date()
    let comps = calendar.dateComponents([.hour, .minute], from: now)
    let currentMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

    func isWithin(start: DateComponents?, end: DateComponents?) -> Bool {
        guard let s = start, let e = end else { return false }
        let sMin = (s.hour ?? 0) * 60 + (s.minute ?? 0)
        let eMin = (e.hour ?? 0) * 60 + (e.minute ?? 0)
        if sMin <= eMin {
            return currentMinutes >= sMin && currentMinutes <= eMin
        } else {
            return currentMinutes >= sMin || currentMinutes <= eMin
        }
    }

    // Time-of-day rules
    for r in remainingTimeOfDay {
        let days = r.daysActive ?? []
        let isActiveDay = days.isEmpty || days.contains(todayName)
        if isActiveDay && isWithin(start: r.startTime, end: r.endTime) {
            applicationTokens.formUnion(r.selection.applicationTokens)
            categoryTokens.formUnion(r.selection.categoryTokens)
        }
    }

    // All-day rules
    for r in remainingAllDay {
        let days = r.daysActive ?? []
        let isActiveDay = days.isEmpty || days.contains(todayName)
        if isActiveDay {
            applicationTokens.formUnion(r.selection.applicationTokens)
            categoryTokens.formUnion(r.selection.categoryTokens)
        }
    }

    store.shield.applications = applicationTokens
    if categoryTokens.isEmpty {
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
    } else {
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(categoryTokens)
    }
}
```

### 3. Day Helper Utilities

```swift
enum DayHelper {
    static let allDayNames: [String] = [
        "Monday", "Tuesday", "Wednesday", "Thursday",
        "Friday", "Saturday", "Sunday"
    ]

    static func getCurrentDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    static func mapSelectedDaysToNames(_ selectedDays: Set<Int>) -> Set<String> {
        return Set(selectedDays.compactMap { index in
            guard index >= 0 && index < allDayNames.count else { return "" }
            return allDayNames[index]
        })
    }
}
```

### 4. MVVM Pattern for Views

```swift
@MainActor
class BlockingViewModel: ObservableObject {
    @Published var activeBlocking: [ScreenTimeRule] = []
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.screentime")
    private let screenTimeUseCase: ScreenTimeUseCase = DIContainer.shared.screenTimeUsecase

    func loadActiveBlocking() {
        let timeLimits: [ScreenTimeRule] = load("timeLimitRules", as: [ScreenTimeRule].self) ?? []
        let timeOfDays: [ScreenTimeRule] = load("timeOfDayRules", as: [ScreenTimeRule].self) ?? []
        let allDays: [ScreenTimeRule] = load("allDayRules", as: [ScreenTimeRule].self) ?? []
        let merged = (timeLimits + timeOfDays + allDays).sorted { $0.createdAt < $1.createdAt }
        activeBlocking = merged
    }

    func unblockRule(_ rule: ScreenTimeRule) {
        switch rule.type {
        case .timeLimit:
            screenTimeUseCase.deleteTimeLimit(id: rule.id)
        case .timeOfDay:
            screenTimeUseCase.deleteTimeOfDay(id: rule.id)
        case .allDay:
            screenTimeUseCase.deleteAllDay(id: rule.id)
        }
        loadActiveBlocking()
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. Shields Not Appearing

**Check**:
- App group ID matches across all targets
- Family Controls authorization granted
- Tokens are properly stored in shared UserDefaults
- Monitor extension is properly configured

#### 2. Time Limits Not Resetting

**Check**:
- `intervalDidStart` is called in monitor extension
- Activity name starts with `daily_` prefix
- Schedule is set to repeat daily

#### 3. Immediate Shields Not Working (Downtime/All Day)

**Check**:
- `isCurrentlyInBlockingPeriod` or `shouldBlockToday` returns correct value
- `ManagedSettingsStore` is called immediately after creating rule
- Time/day validation logic is correct

#### 4. Extension Not Receiving Events

**Check**:
- Monitor extension entitlements include app group
- Events are created with correct naming convention
- DeviceActivityCenter monitoring is successfully started

---

## Quick Reference

### Event Naming Convention

| Type | App Event | Category Event |
|------|-----------|----------------|
| Time Limit | `limitReached_app_{uuid}` | `limitReached_category_{uuid}` |
| Downtime | `timeOfDay_app_{uuid}` | `timeOfDay_category_{uuid}` |
| All Day | `allDay_app_{uuid}` | `allDay_category_{uuid}` |

### Activity Name Convention

| Type | Format |
|------|--------|
| Time Limit | `daily_{ruleId}` |
| Downtime | `timeOfDay_{ruleId}` |
| All Day | `allDay_{ruleId}` |

### UserDefaults Keys

```swift
"timeLimitRules"     // [ScreenTimeRule]
"timeOfDayRules"     // [ScreenTimeRule]
"allDayRules"        // [ScreenTimeRule]
"tokenMapping"       // [String: Data] (ApplicationToken)
"categoryTokens"     // [String: Data] (ActivityCategoryToken)
```

### File Structure

```
YourApp/
├── Sources/
│   ├── Core/
│   │   └── DataDepency/
│   │       └── DIContainer.swift
│   ├── Data/
│   │   └── Repositories/
│   │       └── ScreenTimeRepository.swift
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── ScreenTimeRule.swift
│   │   │   └── AppSelectionEntity.swift
│   │   └── Usecases/
│   │       └── ScreenTimeUseCase.swift
│   ├── Presentation/
│   │   ├── Blocking/
│   │   │   ├── AllDaySheet/
│   │   │   ├── DowntimeSheet/
│   │   │   └── BlockingView/
│   │   └── Preference/
│   │       └── ScreenTimeView/
│   └── Helper/
│       ├── ScreenTimeEvents.swift
│       ├── AllDayConfig.swift
│       ├── TimeOfDayConfig.swift
│       ├── TimeLimit.swift
│       ├── TimeLimitConfig.swift
│       └── TimeOfDayHelper.swift
└── YourApp.entitlements

DeviceActivityMonitor/
├── DeviceActivityMonitorExtension.swift
└── DeviceActivityMonitor.entitlements

Shield/
├── ShieldConfigurationExtension.swift
└── Info.plist
```

---

## Conclusion

This guide provides a complete reference for implementing Apple's Screen Time API with three blocking types. The key differences are:

1. **App Limit**: Time-based quota with threshold trigger, daily auto-reset
2. **Downtime**: Schedule-based with immediate blocking during time windows
3. **All Day**: Day-based with immediate blocking on selected days

The unified `ScreenTimeRule` model and consistent repository pattern make it easy to manage all three types while maintaining clean separation of concerns.
