# Feature Modules

## V1 (existing)

| Feature | Key Paths |
|---|---|
| Home | `Presentation/MainTabs/HomeTab/` |
| Quran | `Presentation/MainTabs/QuranTab/` |
| Blocking | `Presentation/MainTabs/BlockingTab/` |
| Settings | `Presentation/MainTabs/SettingsTab/` |
| Recite to Unblock | `Presentation/ReciteToUnblock/` (4 files — major V2 change area) |
| Components | `Presentation/Components/` (23 shared components) |

## V2 New

| Feature | Key Paths |
|---|---|
| Dashboard | `Presentation/MainTabs/DashboardTab/` |
| Ayah Pool | `Presentation/AyahPool/` (new — linked from Settings or Blocking) |
| Unblock Duration Selection | `Presentation/UnblockDurationSelection/` (new route) |
| Dashboard Extension | `Extensions/DeenFirstActivityReport/` |

## Domain Services (V2 additions)

| Service | Path |
|---|---|
| `PendingChangeService` | `Domain/Services/PendingChangeService.swift` |
| `AyahPoolService` | `Domain/Services/AyahPoolService.swift` |
| `DashboardDataWriter` | `Domain/Services/DashboardDataWriter.swift` |
| `ScreenTimeRulesService+Unblock` | `Domain/Services/ScreenTimeRulesService+Unblock.swift` |
| `DeenScoreCalculator` | `Shared/DeenScoreCalculator.swift` (pure function, shared with extension) |

## New SwiftData Entities (V2)

| Entity | Path |
|---|---|
| `PendingRuleChange` | `Domain/Entities/PendingRuleChange.swift` |
| `AyahPoolItem` | `Domain/Entities/AyahPoolItem.swift` |

## Cross-cutting (Shared/)

| File | Purpose |
|---|---|
| `AppGroupConstants.swift` | All App Group key constants |
| `ScreenTimeEvents.swift` | DeviceActivity event types |
| `DeenScoreCalculator.swift` | Pure Deen Score calculation (V2) |
