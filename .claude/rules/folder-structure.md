# Folder Structure

```
deenfirst/Sources/
├── Core/
│   ├── DataDependency/
│   │   └── DIContainer.swift           ← all service access
│   ├── Networking/
│   │   └── HTTPClient.swift            ← Alamofire wrapper
│   └── SceneNavigation/
│       └── Router.swift                ← Route enum + NavigationPath
│
├── Domain/
│   ├── Entities/
│   │   ├── user.swift
│   │   ├── session.swift
│   │   ├── ScreenTimeRule.swift        ← +isHardMode, +isLockEditingEnabled (V2)
│   │   ├── PendingRuleChange.swift     ← NEW V2
│   │   └── AyahPoolItem.swift          ← NEW V2
│   └── Services/
│       ├── ScreenTimeRulesService.swift
│       ├── ScreenTimeRulesService+Unblock.swift  ← tier logic, longer-wins (V2)
│       ├── PendingChangeService.swift  ← NEW V2
│       ├── AyahPoolService.swift       ← NEW V2
│       ├── DashboardDataWriter.swift   ← NEW V2
│       ├── SessionService.swift        ← +isUnblockSession (V2)
│       ├── ReciteToUnblockViewModel.swift ← major V2 changes
│       ├── AudioPlayerService.swift
│       ├── QuranService.swift
│       └── ...
│
├── Data/
│   ├── DataSource/
│   │   └── API/
│   │       ├── QuranAPIDataSource.swift
│   │       └── WhisperAPIDataSource.swift
│   └── Repositories/
│       └── ...
│
├── Presentation/
│   ├── MainTabs/
│   │   ├── HomeTab/
│   │   ├── QuranTab/
│   │   ├── BlockingTab/
│   │   ├── DashboardTab/               ← NEW V2
│   │   └── SettingsTab/
│   ├── ReciteToUnblock/                ← 4 files, core V2 change area
│   ├── AyahPool/                       ← NEW V2
│   ├── UnblockDurationSelection/       ← NEW V2
│   └── Components/                     ← 23 shared components
│
├── Shared/                             ← shared with extensions
│   ├── AppGroupConstants.swift
│   ├── ScreenTimeEvents.swift
│   └── DeenScoreCalculator.swift       ← NEW V2 (pure function)
│
└── Utils/

deenfirst/Tests/
├── Domain/
│   └── Services/
└── Utils/

Extensions/
├── ScreenTimeMonitor/
├── Shield/
└── DeenFirstActivityReport/            ← NEW V2
```

## Key rules

- New V2 features go under their own folder in `Presentation/`
- Shared code used by extensions MUST live in `Shared/` — not in `Domain/` or `Presentation/`
- Extensions never import SwiftData — only `Shared/` files
- `DeenScoreCalculator` is a pure function — no dependencies on SwiftData or network
