# Screen Time Feature - Complete Reference

## Feature Explanation

### Overview
DeenFirst implements app blocking using Apple's DeviceActivity, ManagedSettings, and Shield frameworks. The system allows users to:
1. Set daily time limits for apps (App Limit)
2. Block apps during specific time windows (Time Limit / Prayer Times)
3. Start focus sessions that block selected apps
4. Temporarily unblock by reciting Quran verses

### How Each Feature Works

#### 1. App Limit (Daily Quota)
- User selects apps/categories and sets a daily quota (e.g., "30 min/day")
- DeviceActivity framework tracks usage in background
- When threshold reached → `eventDidReachThreshold` fires in ScreenTimeMonitor extension
- Extension applies shield to blocked apps
- Shields reset at midnight via `intervalDidStart`
- Triggered rules persisted in `triggeredRuleIds` for cross-process tracking

#### 2. Time Limit (Schedule-Based Blocking)
- User sets time windows (e.g., "9 AM - 5 PM", "During Fajr prayer")
- Shield applies during scheduled window
- Extension handles window entry/exit
- Supports overnight schedules (e.g., 11 PM - 6 AM)
- Time windows persisted in SharedUserDefaults for extension access

#### 3. Focus Session Integration
- When Quran session starts → `SessionService.applySessionShields()`
- Session apps loaded from UserDefaults (saved during Setup)
- Session shield combines with existing rule shields (union operation)
- `isSessionActive` flag set to true
- When session ends → `removeSessionShield()` calls `reapplyActiveShields()`
- Atomic replace ensures no gap in protection

#### 4. Temporary Unblock
- User can unblock for N minutes (5 or 15)
- All shields removed immediately via `removeAllShields()`
- DeviceActivity schedule created that ends at expiry time
- Extension's `intervalDidEnd` fires → `handleTempUnblockExpired()`
- Re-applies all triggered AppLimit rules + TimeLimit rules in current window
- Works even if main app is backgrounded/killed

#### 5. Recite to Unblock
- Shield shows "🎙️ Recite to Unblock" button
- Button press → `ShieldActionExtension` sets `reciteRequested` flag
- RootView detects flag on foreground → navigates to `ReciteToUnblockView`
- User records recitation → OpenAI Whisper API transcribes
- Similarity score calculated (70% threshold to pass)
- On pass → `temporaryUnblock(minutes:)` called

#### 6. Orphaned Session Cleanup
- If app force-killed during session
- On next launch → `cleanupOrphanedSessions()` called
- Marks incomplete sessions as completed
- Clears `isSessionActive` flag
- Calls `reapplyActiveShields()` to restore rule-based state

### Data Flow: Setup → Rules → Session → Unblock

```
Setup Flow (Initial Rules)
│
├─ PermissionView → Request Screen Time authorization
├─ SetupView → Select apps to block + set daily limit + select prayer times
├─ SetupViewModel.saveSetup()
│  ├─ Creates AppLimit rule (if daily limit selected)
│  ├─ Creates TimeLimit rules (one per prayer time)
│  └─ Saves app selection to UserDefaults (for Focus Sessions)
└─ SetupSummary → Preview rules before saving
      └─ Post .didCompleteScreenTimeSetup → Navigate to MainTabView

Focus Session Flow
│
├─ QuranTab → Select Surahs → Start Session
├─ SessionService.startSession()
│  ├─ Load saved app tokens from UserDefaults
│  ├─ Set isSessionActive = true
│  └─ Apply session shield (union with existing shields)
├─ ActiveSessionView → Audio plays, timer runs
└─ SessionService.endSession()
   └─ Remove session shield, reapply rule-based shields

Recite to Unblock Flow
│
├─ User tries to open blocked app → Shield appears
├─ Taps "🎙️ Recite to Unblock" → ShieldActionExtension sets flag
├─ RootView detects on foreground → Navigate to ReciteToUnblockView
├─ Load random ayah (Surah 1-7) → Record recitation
├─ Whisper API transcribes → Calculate similarity
└─ If score >= 70% → temporaryUnblock(5 or 15 minutes)
```

### Key Architecture Patterns

| Pattern | Implementation |
|---------|----------------|
| MVVM | ViewModels handle business logic, @Published properties for UI binding |
| Repository | Data abstraction through Repository layer (ScreenTimeRulesRepository, SessionRepository) |
| Service Layer | Business logic in separate service classes (ScreenTimeRulesService, SessionService) |
| Dependency Injection | DIContainer provides singleton services to all ViewModels |
| Extension Architecture | Background monitoring in separate processes (ScreenTimeMonitor, Shield, ShieldAction) |
| App Group Communication | SharedUserDefaults (group.com.aydev.deenfirst) for cross-process data |
| Union-Based Shielding | Multiple sources contribute without overwriting each other |
| Coordinator | RootView manages navigation, deep links, notification listeners |

### Cross-Process Communication (App Group)

The main app and extensions communicate via SharedUserDefaults with these keys:

| Key | Purpose | Who Writes | Who Reads |
|-----|---------|------------|-----------|
| `ruleTokens` | Per-rule app/category tokens | MainApp | Extension |
| `triggeredRuleIds` | AppLimit rules that fired today | Extension | MainApp + Extension |
| `isSessionActive` | Focus session state | SessionService | MainApp + Extension |
| `unblockExpiry` | Temporary unblock timestamp | MainApp | Extension |
| `reciteRequested` | Recite-to-unblock flag | ShieldAction | RootView |
| `tokenMapping` | Session app tokens | SetupViewModel | SessionService |
| `categoryTokens` | Session category tokens | SetupViewModel | SessionService |

---

## File Structure

```
deenfirst/
│
├── ScreenTimeMonitor/                          # Background Extension
│   ├── DeviceActivityMonitorExtension.swift    # Threshold events, daily reset, temp unblock expiry
│   └── ScreenTimeMonitor.entitlements          # Family controls + app group
│
├── Shield/                                     # Shield UI Extension
│   └── ShieldConfigurationExtension.swift      # Custom shield UI, messages, buttons
│
├── ShieldAction/                               # Shield Action Extension
│   └── ShieldActionExtension.swift            # Handle button taps (close, recite)
│
└── deenfirst/Sources/
    │
    ├── DeenFirstApp.swift                     # App entry point
    ├── RootView.swift                          # Coordinator - navigation, notifications, env objects
    │
    ├── Core/DataDependency/
    │   └── DIContainer.swift                   # Dependency injection - all services registered here
    │
    ├── Domain/
    │   ├── Entities/
    │   │   ├── ScreenTimeRule.swift            # Rule entity (tokens, schedule, display helpers)
    │   │   └── TimeLimitConfig.swift           # Time limit config entity
    │   │
    │   └── Services/
    │       ├── ScreenTimeRulesService.swift    # Main service - CRUD, shield management
    │       ├── ScreenTimeRulesService+Unblock.swift  # Temp unblock, DeviceActivity scheduling
    │       ├── DeviceActivityManager.swift     # DeviceActivity framework wrapper
    │       ├── ManagedSettingsWrapper.swift    # Shield framework wrapper (union/replace/remove)
    │       ├── SessionService.swift            # Focus session lifecycle, shield integration
    │       └── AuthService.swift               # Auth (used in setup flow)
    │
    ├── Data/
    │   └── Repositories/
    │       ├── ScreenTimeRulesRepository.swift # Rule persistence
    │       └── SessionRepository.swift         # Session persistence
    │
    ├── Shared/
    │   ├── ScreenTimeEvents.swift              # Event creation, token storage, triggered tracking
    │   ├── AppGroupConstants.swift             # All storage keys, shared defaults access
    │   └── DayHelper.swift                     # Day/date utilities
    │
    ├── Utils/
    │   ├── DeviceActivityScheduleHelper.swift  # Schedule helpers (daily, custom, full-day)
    │   └── UserPersistenceHelper.swift         # User data persistence (streaks, last active)
    │
    └── Presentation/
        │
        ├── FocusSession/
        │   └── SetupView.swift                 # Initial setup UI - app selection
        │
        ├── Setup/
        │   ├── SetupViewModel.swift            # Setup logic - creates initial rules
        │   └── SetupSummary.swift              # Preview rules before saving
        │
        ├── MainTabs/
        │   ├── BlockingTab/
        │   │   ├── BlockingTabView.swift       # Main blocking tab UI - lists all rules
        │   │   ├── BlockingTabViewModel.swift  # Load rules, countdown timer, delete
        │   │   ├── TimeLimitView.swift         # Time limit create/edit UI
        │   │   ├── TimeLimitViewModel.swift    # Time limit form logic
        │   │   ├── AppLimitView.swift          # App limit create/edit UI
        │   │   └── AppLimitViewModel.swift     # App limit form logic
        │   │
        │   └── QuranTab/
        │       ├── FocusSectionView.swift      # Start session UI
        │       ├── FocusSectionViewModel.swift # Session configuration
        │       └── SessionFinishView.swift     # Session completion UI
        │
        ├── Components/BlockingTabComps/
        │   ├── CreateBlockSheet.swift          # Sheet for creating new blocks
        │   └── EmptyBlocksView.swift           # Empty state UI
        │
        └── ReciteToUnblock/
            ├── ReciteToUnblockView.swift       # Recitation UI - recording, results
            └── ReciteToUnblockViewModel.swift  # Whisper API, similarity, unblock trigger
```

---

## Quick Copy Command (Terminal)

```bash
# Create ZIP file in Downloads folder with all Screen Time files
zip -j ~/Downloads/ScreenTimeFeature.zip \
  ScreenTimeMonitor/DeviceActivityMonitorExtension.swift \
  ScreenTimeMonitor/ScreenTimeMonitor.entitlements \
  Shield/ShieldConfigurationExtension.swift \
  ShieldAction/ShieldActionExtension.swift \
  deenfirst/Sources/DeenFirstApp.swift \
  deenfirst/Sources/RootView.swift \
  deenfirst/Sources/Core/DataDependency/DIContainer.swift \
  deenfirst/Sources/Domain/Entities/ScreenTimeRule.swift \
  deenfirst/Sources/Domain/Entities/TimeLimitConfig.swift \
  deenfirst/Sources/Domain/Services/ScreenTimeRulesService.swift \
  deenfirst/Sources/Domain/Services/ScreenTimeRulesService+Unblock.swift \
  deenfirst/Sources/Domain/Services/DeviceActivityManager.swift \
  deenfirst/Sources/Domain/Services/ManagedSettingsWrapper.swift \
  deenfirst/Sources/Domain/Services/SessionService.swift \
  deenfirst/Sources/Data/Repositories/ScreenTimeRulesRepository.swift \
  deenfirst/Sources/Data/Repositories/SessionRepository.swift \
  deenfirst/Sources/Shared/ScreenTimeEvents.swift \
  deenfirst/Sources/Shared/AppGroupConstants.swift \
  deenfirst/Sources/Shared/DayHelper.swift \
  deenfirst/Sources/Utils/DeviceActivityScheduleHelper.swift \
  deenfirst/Sources/Utils/UserPersistenceHelper.swift \
  deenfirst/Sources/Presentation/FocusSession/SetupView.swift \
  deenfirst/Sources/Presentation/Setup/SetupViewModel.swift \
  deenfirst/Sources/Presentation/Setup/SetupSummary.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/BlockingTabView.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/BlockingTabViewModel.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/TimeLimitView.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/TimeLimitViewModel.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/AppLimitView.swift \
  deenfirst/Sources/Presentation/MainTabs/BlockingTab/AppLimitViewModel.swift \
  deenfirst/Sources/Presentation/MainTabs/QuranTab/FocusSectionView.swift \
  deenfirst/Sources/Presentation/MainTabs/QuranTab/FocusSectionViewModel.swift \
  deenfirst/Sources/Presentation/MainTabs/QuranTab/SessionFinishView.swift \
  deenfirst/Sources/Presentation/Components/BlockingTabComps/CreateBlockSheet.swift \
  deenfirst/Sources/Presentation/Components/BlockingTabComps/EmptyBlocksView.swift \
  deenfirst/Sources/Presentation/ReciteToUnblock/ReciteToUnblockView.swift \
  deenfirst/Sources/Presentation/ReciteToUnblock/ReciteToUnblockViewModel.swift

echo "✅ Created ~/Downloads/ScreenTimeFeature.zip with 40+ files"
```

---

## Summary

This feature integrates:
- **3 iOS Extensions** (ScreenTimeMonitor, Shield, ShieldAction)
- **5 Domain Services** (ScreenTimeRules, Session, DeviceActivity, ManagedSettings, Auth)
- **15+ UI Components** (Setup, Blocking, Session, ReciteToUnblock)
- **Cross-process communication** via App Group UserDefaults
- **OpenAI Whisper API** for Arabic transcription
