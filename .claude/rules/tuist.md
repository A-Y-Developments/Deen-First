# Tuist Rules

## Core principle
All project structure changes go through Tuist. Never touch `.xcodeproj` directly — it is generated.

## When to run make generate
Run `make generate` after ANY of these:
- Changes to `Project.swift`
- Adding/removing source files or folders
- Adding/removing targets or dependencies
- Changing bundle IDs, entitlements, or build settings

If you skip this, Xcode won't see your changes. Always run it before building.

## Adding dependencies
All SPM dependencies go in `Tuist/Package.swift`, not `Project.swift`.
After editing `Package.swift` → run `make install` first, then `make generate`.

## Adding a new target
Only in `Project.swift`. Steps:
1. Define the target in `Project.swift`
2. Add it to the `targets` array in `makeApp()`
3. Run `make generate`
4. Never create a new Xcode target manually via Xcode UI

## Extension targets (ScreenTimeMonitor, Shield, DeenFirstActivityReport)
- No SwiftData in extension targets
- No network calls in `DeenFirstActivityReport`
- No write to App Group from `DeenFirstActivityReport` — read only
- Cross-process data via `AppGroupConstants` only — never inline keys
- Use `os_log` not `print()` in all extension targets

## App Groups
Shared suite name always via `AppGroupConstants.suiteName`.
Never hardcode `"group.com.aydev.deenfirst"` inline anywhere.

## Hard rules
- Never edit `.xcodeproj` — it is generated, changes will be overwritten
- Never add entitlements manually in Xcode — define in `Project.swift`
- Never run `xcodebuild` without running `make generate` first if `Project.swift` changed
- `make build` and `make test` use the generated project — always regenerate first