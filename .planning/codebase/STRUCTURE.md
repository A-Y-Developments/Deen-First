# Codebase Structure

**Analysis Date:** 2026-02-03

## Directory Layout

```
[project-root]/
├── surahfocus/              # Main source directory
│   ├── surahfocusApp.swift  # App entry point (@main)
│   ├── ContentView.swift    # Root view
│   └── Assets.xcassets/     # Asset catalog
│       ├── AppIcon.appiconset/
│       ├── AccentColor.colorset/
│       └── Contents.json
├── surahfocus.xcodeproj/    # Xcode project (generated, committed)
│   └── project.pbxproj      # Project configuration
├── .planning/               # Planning directory (GSD)
└── .git/                    # Git repository
```

## Directory Purposes

**surahfocus/:**
- Purpose: Main application source code
- Contains: Swift view files, asset catalogs
- Key files: `surahfocusApp.swift`, `ContentView.swift`

**surahfocus.xcodeproj/:**
- Purpose: Xcode project configuration
- Contains: Build settings, file references, scheme configuration
- Key files: `project.pbxproj`
- Generated: Yes (managed by Xcode)
- Committed: Yes

**Assets.xcassets/:**
- Purpose: Asset catalog for images, colors, icons
- Contains: `.appiconset`, `.colorset` directories with `Contents.json`
- Key files: `AppIcon.appiconset/`, `AccentColor.colorset/`

## Key File Locations

**Entry Points:**
- `surahfocus/surahfocusApp.swift`: App root with `@main` attribute

**Views:**
- `surahfocus/ContentView.swift`: Root view for the app

**Assets:**
- `surahfocus/Assets.xcassets/`: All visual assets

**Configuration:**
- `surahfocus.xcodeproj/project.pbxproj`: Build configuration, target settings

**Testing:**
- Not applicable (no test files present)

## Naming Conventions

**Files:**
- PascalCase for structs: `ContentView.swift`, `surahfocusApp.swift`
- Lowercase for directories: `surahfocus/`, `Assets.xcassets/`

**Directories:**
- Project root lowercase: `surahfocus/`
- Asset directories use suffix: `.appiconset`, `.colorset`

## Where to Add New Code

**New Feature:**
- Primary code: `surahfocus/` (create new Swift files)
- Tests: Not configured (add `Tests/` directory)

**New Component/Module:**
- Implementation: `surahfocus/[ComponentName].swift`
- Preview: Add `#Preview` macro at bottom of file

**Utilities:**
- Shared helpers: `surahfocus/Utilities/` (create directory)
- Extensions: `surahfocus/Extensions/` (create directory)

## Special Directories

**surahfocus.xcodeproj/:**
- Purpose: Xcode project configuration
- Generated: Yes (by Xcode)
- Committed: Yes (source control)

**Assets.xcassets/:**
- Purpose: Compiled asset catalog
- Generated: No (managed by developer)
- Committed: Yes

## Project Metadata

**Bundle Identifier:** `com.aydev.surahfocus`
**Target Name:** `surahfocus`
**Product:** `surahfocus.app`
**Development Team:** `32T8HNVYGX`
**Swift Version:** 5.0
**Deployment Target:** iOS 26.0
**Supported Devices:** iPhone + iPad (Universal)

---

*Structure analysis: 2026-02-03*
