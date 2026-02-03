# Coding Conventions

**Analysis Date:** 2026-02-03

## Naming Patterns

**Files:**
- PascalCase for types: `ContentView.swift`, `surahfocusApp.swift`
- File names match the primary type they contain

**Functions:**
- camelCase for computed properties: `body`

**Types:**
- PascalCase for structs: `ContentView`, `surahfocusApp`
- Protocol conformance declared with trailing syntax: `struct ContentView: View`

**Variables:**
- Not detected (minimal codebase currently)

## Code Style

**Formatting:**
- Swift standard formatting (4-space indentation)
- Xcode default formatting

**Linting:**
- None configured (standard Xcode defaults)

**Project Version:**
- Xcode 26.0
- Swift 6.0 (implied by Xcode version)

## Import Organization

**Order:**
1. Framework imports at top of file: `import SwiftUI`
2. No third-party imports detected

**Path Aliases:**
- None (standard iOS project structure)

## Error Handling

**Patterns:**
- No error handling detected in current codebase

## Logging

**Framework:** None (no print statements or logging detected)

**Patterns:**
- No logging present in current codebase

## Comments

**When to Comment:**
- Standard file header with Xcode template: filename, project name, creation date

**JSDoc/TSDoc:**
- None (Swift uses standard comments)

## Function Design

**Size:** Not applicable (minimal computed properties only)

**Parameters:** None detected

**Return Values:**
- Some View returned from SwiftUI body properties

## Module Design

**Exports:**
- No explicit exports (iOS apps use app entry point)

**Barrel Files:** Not applicable

## SwiftUI Conventions

**View Modifiers:**
- Chained with dot syntax: `.padding()`, `.imageScale(.large)`
- Modifier order: view-specific modifiers first, layout modifiers last

**Preview:**
- Use `#Preview` macro: `#Preview { ContentView() }`
- Previews placed at end of view file

## App Entry Point

**Structure:**
- `@main` attribute on App struct: `surahfocusApp.swift`
- App struct conforms to `App` protocol
- WindowGroup for scene management

---

*Convention analysis: 2026-02-03*
