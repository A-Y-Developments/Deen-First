# iOS PROJECT SETUP - Build System & Tooling
# Deen First

> Standalone guide for setting up the Deen First iOS project with Tuist, Clean Architecture + MVVM

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Initialization](#project-initialization)
- [Tuist Configuration](#tuist-configuration)
- [Environment Setup](#environment-setup)
- [Makefile](#makefile)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Extension Targets](#extension-targets)
- [Quick Start](#quick-start)

---

## Prerequisites

1. **Install Tuist**
   ```bash
   curl -Ls https://install.tuist.io | bash
   ```

2. **Install xcpretty** (for clean build output)
   ```bash
   gem install xcpretty
   ```

3. **Xcode** — Latest version from App Store

4. **iOS Deployment Target**: 17.0+

---

## Project Initialization

### Step 1: Create Project Directory

```bash
mkdir deenfirst
cd deenfirst
```

### Step 2: Create Folder Structure

```bash
# Source folders
mkdir -p Sources/{Core/{DataDependency,SceneNavigation,Networking},Data/{DataSource/API,Repositories},Domain/{Entities,Services},Presentation/{Auth,Paywall,Survey,Summary,Setup,MainTabs/{HomeTab,QuranTab,BlockingTab,SettingsTab/EmergencyUnblock},ReciteToUnblock,QuranReading,FocusSession,Components/{BlockingTabComps,HomeTabComps,FocusSessionComps,SettingsTabComps}},Shared,Utils}

# Resources
mkdir -p Resources/Assets.xcassets

# Tuist
mkdir -p Tuist

# Screen Time Extensions
mkdir -p ScreenTimeMonitor Shield
```

### Step 3: Create Required Files

```bash
touch Project.swift
touch Tuist/Package.swift
touch .env
touch Makefile
```

---

## Tuist Configuration

### Project.swift

```swift
import ProjectDescription

let project = Project(
    name: "deenfirst",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetForVariableName: .deenfirst
        )
    ),
    targets: [
        // Main App Target
        .target(
            name: "deenfirst",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.aydev.deenfirst",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:],
                "NSFamilyControlsUsageDescription": "Deen First needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"],
                "NSSpeechRecognitionUsageDescription": "Used to verify your Quran recitation.",
                "NSMicrophoneUsageDescription": "Record your Quran recitation to unlock apps.",
                "NSUserTrackingUsageDescription": "We use analytics to improve your experience."
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "RevenueCat"),
                .external(name: "Alamofire")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "YOUR_TEAM_ID",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
                ]
            )
        ),

        // DeviceActivityMonitor Extension
        .target(
            name: "ScreenTimeMonitor",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.aydev.deenfirst.ScreenTimeMonitor",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.device-activity.monitor",
                    "NSExtensionPrincipalClass": "DeviceActivityMonitorExtension"
                ]
            ]),
            sources: ["ScreenTimeMonitor/**"],
            dependencies: []
        ),

        // ShieldConfiguration Extension
        .target(
            name: "Shield",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.aydev.deenfirst.Shield",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.shield-configuration",
                    "NSExtensionPrincipalClass": "ShieldConfigurationExtension"
                ]
            ]),
            sources: ["Shield/**"],
            dependencies: []
        )
    ]
)
```

### Tuist/Package.swift

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init([
        .remote(
            url: "https://github.com/RevenueCat/purchases-ios.git",
            requirement: .upToNextMajor(from: "5.57.0")
        ),
        .remote(
            url: "https://github.com/Alamofire/Alamofire.git",
            requirement: .upToNextMajor(from: "5.10.0")
        )
    ])
)
```

---

## Environment Setup

### .env

```bash
TUIST_COMPANY_ID=com.aydev
TUIST_TEAM_ID=YOUR_TEAM_ID_HERE
TUIST_BASE_BUNDLE_ID=com.aydev.deenfirst
REVENUECAT_API_KEY=your_revenuecat_api_key_here
```

---

## Makefile

```makefile
.PHONY: all env generate build clean install edit test

all: clean install env generate

env:
	@echo "✓ Loading environment variables..."

generate:
	@echo "✓ Generating Xcode project..."
	@tuist generate

build:
	@echo "✓ Building app..."
	@xcodebuild -workspace deenfirst.xcworkspace \
		-scheme deenfirst \
		-destination 'platform=iOS Simulator,name=iPhone 15' \
		build | xcpretty

clean:
	@echo "✓ Cleaning build artifacts..."
	@rm -rf DerivedData
	@tuist clean

install:
	@echo "✓ Installing dependencies..."
	@tuist install

edit:
	@tuist edit

test:
	@xcodebuild test \
		-workspace deenfirst.xcworkspace \
		-scheme deenfirst \
		-destination 'platform=iOS Simulator,name=iPhone 15'
```

**Usage:**
```bash
make           # Full clean build
make generate  # Regenerate Xcode project (after adding files)
make build     # Build the app
make clean     # Clean build artifacts
make install   # Fetch/update dependencies
make edit      # Open in Xcode
```

---

## Project Structure

```
deenfirst/
├── Project.swift
├── Tuist/
│   └── Package.swift
├── .env
├── Makefile
│
├── Sources/                        # Main app source
│   ├── DeenFirstApp.swift          # @main entry point
│   ├── RootView.swift              # NavigationStack + state gating
│   ├── Core/
│   │   ├── DataDependency/DIContainer.swift
│   │   ├── Networking/HTTPClient.swift
│   │   └── SceneNavigation/Router.swift
│   ├── Domain/
│   │   ├── Entities/               # snake_case files
│   │   └── Services/               # PascalCase files
│   ├── Data/
│   │   ├── DataSource/
│   │   │   ├── API/
│   │   │   └── LocalDataSource.swift
│   │   └── Repositories/
│   ├── Presentation/
│   │   ├── Auth/
│   │   ├── Paywall/
│   │   ├── Survey/
│   │   ├── Summary/
│   │   ├── Setup/
│   │   ├── MainTabs/
│   │   │   ├── HomeTab/
│   │   │   ├── QuranTab/
│   │   │   ├── BlockingTab/
│   │   │   └── SettingsTab/
│   │   ├── ReciteToUnblock/
│   │   ├── QuranReading/
│   │   ├── FocusSession/
│   │   └── Components/
│   ├── Shared/                     # Shared with extensions
│   └── Utils/
│
├── Resources/
│   └── Assets.xcassets
│
├── ScreenTimeMonitor/              # Extension target
│   └── DeviceActivityMonitorExtension.swift
│
└── Shield/                         # Extension target
    └── ShieldConfigurationExtension.swift
```

---

## Dependencies

### Swift Package Manager (via Tuist)

| Library | Version | Purpose |
|---------|---------|---------|
| RevenueCat | 5.57.0+ | Subscription management |
| Alamofire | 5.10.0+ | HTTP networking |

### Native Frameworks

| Framework | Purpose |
|-----------|---------|
| SwiftUI | UI framework |
| SwiftData | Local persistence |
| FamilyControls | Screen Time authorization + app picker |
| ManagedSettings | Shield application |
| DeviceActivity | Usage monitoring |
| AVFoundation | Audio playback + recording |
| MediaPlayer | Now Playing info (Control Center) |
| AuthenticationServices | Sign in with Apple |
| UserNotifications | Push notifications |

### External Services

| Service | Purpose |
|---------|---------|
| RevenueCat | Subscription management |
| OpenAI Whisper API | Recitation transcription (Recite to Unblock) |
| QuranAPI.pages.dev | Quran text + audio URLs (primary) |
| AlQuranAPI | Quran data (secondary source) |

---

## Extension Targets

### DeviceActivityMonitor Extension

**Purpose**: Background process that monitors app usage and applies shields.

**Bundle ID**: `com.aydev.deenfirst.ScreenTimeMonitor`

**Required Entitlements** (`ScreenTimeMonitor.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.aydev.deenfirst</string>
</array>
```

**Key implementations**:
- `intervalDidStart` — resets App Limit shields at midnight
- `intervalDidEnd` — clears shields when interval ends
- `eventDidReachThreshold` — applies shield when usage limit reached
- Reads token mappings from `UserDefaults(suiteName: "group.com.aydev.deenfirst")`

### ShieldConfiguration Extension

**Purpose**: Custom UI shown when an app is blocked.

**Bundle ID**: `com.aydev.deenfirst.Shield`

**What it shows**:
- Deen First icon + branding
- "Time to read Quran instead 🌙"
- Close button (branded color)

### App Group

**Identifier**: `group.com.aydev.deenfirst`

All three targets (main app + both extensions) must share this app group. This allows:
- Main app to write rule configs and token mappings
- Extensions to read them and apply shields

---

## Quick Start

### 1. Setup project

```bash
# Create .env with your Team ID
echo "TUIST_TEAM_ID=YOUR_TEAM_ID" >> .env

# Generate project
make
```

### 2. Open in Xcode

```bash
make edit
# or
open deenfirst.xcworkspace
```

### 3. Configure Xcode capabilities

In Xcode for the main app target:
- Enable **Family Controls** capability
- Enable **App Groups** → add `group.com.aydev.deenfirst`

For ScreenTimeMonitor extension target:
- Enable **Family Controls**
- Enable **App Groups** → add `group.com.aydev.deenfirst`

### 4. Set RevenueCat API Key

In `DeenFirstApp.swift`, update:
```swift
#if DEBUG
Purchases.configure(withAPIKey: "your_test_api_key")
#else
Purchases.configure(withAPIKey: "your_production_api_key")
#endif
```

### 5. Set OpenAI API Key

In the appropriate service/constants file, set your OpenAI API key for Whisper transcription (used in Recite to Unblock).

---

## Common Tuist Commands

```bash
tuist generate          # Generate Xcode project
tuist install           # Fetch dependencies
tuist clean             # Clean generated files
tuist edit              # Open in Xcode
tuist cache             # Cache dependencies (faster subsequent installs)
```

---

## Common Issues

| Issue | Solution |
|-------|---------|
| Xcode project out of sync | Run `make generate` |
| Dependencies not found | Run `make install` then `make generate` |
| Build errors after merging | `make clean` then `make` |
| Screen Time features don't work | Must test on physical device (iOS 17+), not simulator |
| Shield doesn't appear | Verify App Group identifier matches across all targets |
| Extension crashes | Check `com.apple.developer.family-controls` entitlement on monitor extension |

---

## Architecture Reference

For detailed code patterns (MVVM, DI, Navigation, etc.), see `PROJECT_RULES.md`.

**Quick Summary:**
- Clean Architecture + MVVM
- Singleton DIContainer for dependency injection
- Router with NavigationStack (all ViewModels as @StateObject in RootView)
- Protocol-oriented services and repositories
- SwiftData for local persistence
- App Groups for Screen Time extension communication
