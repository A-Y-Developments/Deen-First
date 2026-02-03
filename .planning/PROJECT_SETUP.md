# iOS PROJECT SETUP - Build System & Tooling

> Standalone guide for setting up new iOS projects with Tuist, Clean Architecture + MVVM

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Initialization](#project-initialization)
- [Tuist Configuration](#tuist-configuration)
- [Environment Setup](#environment-setup)
- [Makefile](#makefile)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
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

3. **Xcode** - Latest version from App Store

4. **iOS Deployment Target**: 17.0+

---

## Project Initialization

### Step 1: Create Project Directory

```bash
mkdir MyApp
cd MyApp
```

### Step 2: Create Folder Structure

```bash
# Source folders
mkdir -p Sources/{Core/{DataDepency,SceneNavigation,ImageCaching,Networking},Data/{DataSource,Repositories},Domain/{Entities,Services},Presentation/Components,Helper,Utils}

# Resources
mkdir -p Resources/{Assets.xcassets,Rive,CSV}

# Tuist
mkdir -p Tuist
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
    name: "MyApp",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetForVariableName: .myApp
        )
    ),
    targets: [
        .target(
            name: "MyApp",
            destinations: .iOS,
            product: .app,
            bundleId: Env.baseBundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "Kingfisher"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": Env.teamId,
                    "CODE_SIGN_STYLE": "Automatic",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
                ]
            )
        )
    ]
)
```

### Tuist/Package.swift

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init(
        [
            .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.10.2")),
            .remote(url: "https://github.com/onevcat/Kingfisher.git", requirement: .upToNextMajor(from: "8.0.0")),
        ]
    )
)
```

---

## Environment Setup

### .env

```bash
TUIST_COMPANY_ID=com.company
TUIST_TEAM_ID=XXXXXXXXXX
TUIST_BASE_BUNDLE_ID=com.company.myapp
```

### Add These to Project.swift

```swift
// Add at top of Project.swift
public extension Env {
    static var companyId: String {
        EnvironmentVariable.shared.string("TUIST_COMPANY_ID") ?? "com.company"
    }

    static var teamId: String {
        EnvironmentVariable.shared.string("TUIST_TEAM_ID") ?? "XXXXXXXXXX"
    }

    static var baseBundleId: String {
        EnvironmentVariable.shared.string("TUIST_BASE_BUNDLE_ID") ?? "\(companyId).MyApp"
    }
}
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
	@xcodebuild -workspace MyApp.xcworkspace \
		-scheme MyApp \
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
		-workspace MyApp.xcworkspace \
		-scheme MyApp \
		-destination 'platform=iOS Simulator,name=iPhone 15'
```

**Usage:**
```bash
make           # Full clean build
make generate   # Generate Xcode project
make build      # Build the app
make clean      # Clean build artifacts
make install    # Fetch dependencies
make edit       # Open in Xcode
```

---

## Project Structure

```
Sources/
├── MyAppApp.swift              # App entry point (@main)
├── RootView.swift              # Main NavigationStack setup
│
├── Core/                       # Infrastructure layer
│   ├── DataDepency/
│   │   └── DIContainer.swift
│   ├── SceneNavigation/
│   │   └── Router.swift
│   ├── ImageCaching/
│   │   └── ImageManager.swift
│   └── Networking/
│       └── APIManager.swift
│
├── Domain/                     # Business logic
│   ├── Entities/
│   │   └── app_data.swift
│   ├── Repositories/
│   │   └── {Name}Repository.swift
│   └── Services/
│       └── {Name}Service.swift
│
├── Data/                       # Data access layer
│   ├── DataSource/
│   │   └── LocalDataSource.swift
│   └── Repositories/
│       └── {Name}RepositoryImpl.swift
│
├── Presentation/               # UI layer
│   ├── Components/
│   │   └── ReusableComponents.swift
│   └── {FeatureName}View/
│       ├── {FeatureName}View.swift
│       └── {FeatureName}Viewmodel.swift
│
├── Helper/                     # Domain-specific utilities
│   └── SpecificHelper.swift
│
└── Utils/                      # Generic extensions
    └── Extensions.swift

Resources/
├── Assets.xcassets
├── Rive/
└── CSV/
```

---

## Dependencies

### Core Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| Alamofire | 5.10.2 | HTTP networking |
| Kingfisher | 8.0.0 | Image loading & caching |
| RiveRuntime | 6.11.4 | Animations (optional) |

### Native Frameworks

```swift
import SwiftUI        // UI framework
import SwiftData      // Persistence
import AVFoundation   // Camera/Media (if needed)
import Vision         # Computer Vision (if needed)
```

---

## Quick Start

### 1. Initialize New Project

```bash
mkdir MyApp && cd MyApp

# Create structure
mkdir -p Sources/{Core/{DataDepency,SceneNavigation},Data/DataSource,Domain/{Entities,Services},Presentation/Components}
mkdir -p Resources/Assets.xcassets Tuist

# Create config files
touch Project.swift Tuist/Package.swift .env Makefile
```

### 2. Configure Tuist

Copy the [Project.swift](#projectswift) and [Tuist/Package.swift](#tuistpackageswift) templates above.

### 3. Setup Environment

Create `.env` with your values:
```bash
TUIST_COMPANY_ID=com.mycompany
TUIST_TEAM_ID=YOUR_TEAM_ID
TUIST_BASE_BUNDLE_ID=com.mycompany.myapp
```

### 4. Generate & Build

```bash
make
```

### 5. Open in Xcode

```bash
make edit
# Or
open MyApp.xcworkspace
```

---

## Common Tuist Commands

```bash
tuist init              # Initialize new project
tuist generate          # Generate Xcode project
tuist install           # Fetch dependencies
tuist clean             # Clean generated files
tuist edit              # Open in Xcode
tuist cache            # Cache dependencies
tuist cache clean      # Clean cache
```

---

## Info.plist Permissions

Add to `infoPlist` in Project.swift as needed:

```swift
infoPlist: .extendingDefault(with: [
    "NSCameraUsageDescription": "App needs camera access",
    "NSPhotoLibraryUsageDescription": "App needs photo library access",
    "NSPhotoLibraryAddUsageDescription": "App needs to save photos",
])
```

---

## Architecture Reference

For detailed architecture patterns (MVVM, DI, Navigation, etc.), see the main [PROJECT_RULES.md](./PROJECT_RULES.md) document.

**Quick Summary:**
- Clean Architecture + MVVM
- Singleton DIContainer for dependency injection
- Router with NavigationStack
- Protocol-oriented services and repositories
- SwiftData for persistence
