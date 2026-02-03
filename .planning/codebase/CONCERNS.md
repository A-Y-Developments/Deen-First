# Codebase Concerns

**Analysis Date:** 2026-02-03

## Tech Debt

**Missing Build System:**
- Issue: Project setup documentation in `.planning/PROJECT_SETUP.md` describes Tuist-based build system with Makefile automation, but actual project uses standard Xcode project
- Files: `.planning/PROJECT_SETUP.md`, `/Users/adithyafp_/Projects/surahfocus/Project.swift` (missing)
- Impact: Development workflow documented doesn't match actual project setup; developers following docs will encounter errors
- Fix approach: Either (1) Implement Tuist build system per PROJECT_SETUP.md or (2) Update documentation to reflect standard Xcode workflow

**Placeholder Configuration Values:**
- Issue: `PROJECT_SETUP.md` contains placeholder team ID `XXXXXXXXXX` which will fail builds
- Files: `.planning/PROJECT_SETUP.md:135`, `.planning/PROJECT_SETUP.md:149`
- Impact: Anyone copying code from docs will get build failures
- Fix approach: Replace with documentation comment indicating user must provide their own team ID

**Inconsistent Deployment Target:**
- Issue: Docs specify iOS 17.0+ but actual project uses iOS 26.0 (future version)
- Files: `.planning/PROJECT_SETUP.md:31`, `/Users/adithyafp_/Projects/surahfocus/surahfocus.xcodeproj/project.pbxproj:181,239`
- Impact: App cannot run on current iOS versions; docs are misleading
- Fix approach: Set deployment target to iOS 17.0 as documented, or update docs to reflect iOS 26.0 intent

## Known Bugs

**Git Repository Initialization:**
- Symptoms: No commits in repository; `git log` fails with exit code 128
- Files: `/Users/adithyafp_/Projects/surahfocus/.git/`
- Trigger: Any git operation requiring commit history
- Workaround: Create initial commit
- Impact: No version control history; cannot rollback changes

**No .gitignore:**
- Symptoms: User-specific Xcode files (xcuserdata) not ignored
- Files: Missing `.gitignore` at root
- Trigger: Standard development workflow
- Workaround: Manually avoid committing user files
- Impact: Repository will contain user-specific settings, causing conflicts

## Security Considerations

**Development Team ID Exposed:**
- Risk: Development team ID `32T8HNVYGX` hardcoded in project file
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus.xcodeproj/project.pbxproj:163,227,256,288`
- Current mitigation: None
- Recommendations: Use environment variable or local xcconfig file for team ID; add `.xcodeproj/xcuserdata/` to .gitignore

**Bundle ID Hardcoded:**
- Risk: Bundle ID `com.aydev.surahfocus` visible in committed project file
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus.xcodeproj/project.pbxproj:269,301`
- Current mitigation: None
- Recommendations: Document bundle ID ownership; consider unique bundle ID per developer environment

**No Secrets Management:**
- Risk: No .env or secrets configuration system documented
- Files: No `.env` file present; `.env` documented in PROJECT_SETUP.md but not implemented
- Current mitigation: None
- Recommendations: Implement .env pattern if API keys needed; add .env to .gitignore

## Performance Bottlenecks

**No Detected Issues:**
- Minimal codebase has no performance concerns yet
- As app grows, watch for: SwiftUI view rebuilds, large asset loading, memory leaks

## Fragile Areas

**Project Configuration:**
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus.xcodeproj/project.pbxproj`
- Why fragile: Xcode project file is machine-generated; manual edits cause corruption
- Safe modification: Use Xcode IDE to modify; never hand-edit
- Test coverage: No tests verify project configuration

**Asset Catalog:**
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus/Assets.xcassets/`
- Why fragile: Missing assets cause runtime crashes; Contents.json must be valid
- Safe modification: Use Xcode Asset Catalog editor
- Test coverage: No tests verify asset presence

**Entry Points:**
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus/surahfocusApp.swift`, `/Users/adithyafp_/Projects/surahfocus/surahfocus/ContentView.swift`
- Why fragile: Changes to @main struct or root view can prevent app launch
- Safe modification: Keep @main on App struct; maintain WindowGroup
- Test coverage: No tests verify app launches successfully

## Scaling Limits

**Monolithic Target:**
- Current capacity: Single target `surahfocus` with 2 Swift files
- Limit: All code in one target; no separation of concerns
- Scaling path: Split into modules (Core, Data, Domain, Presentation) per PROJECT_SETUP.md architecture

**No Dependency Management:**
- Current capacity: No external dependencies
- Limit: Manual Swift Package Management via Xcode
- Scaling path: Implement Tuist for dependency management or use Package.swift

**No Navigation Structure:**
- Current capacity: Single view
- Limit: Adding more views requires implementing navigation
- Scaling path: Implement NavigationStack per PROJECT_SETUP.md architecture

## Dependencies at Risk

**No External Dependencies:**
- Risk: None (uses only SwiftUI)
- Impact: N/A
- Migration plan: N/A

**SwiftUI:**
- Risk: Apple framework changes between iOS versions
- Impact: iOS 26.0 deployment target may require future SwiftUI API updates
- Migration plan: Monitor iOS 26 beta; test with new SDKs

## Missing Critical Features

**Test Infrastructure:**
- Problem: No test target, no test files, no testing framework configured
- Files: Entire test infrastructure missing
- Blocks: Confidence in code changes; refactoring safety
- Priority: High

**Error Handling:**
- Problem: No error handling patterns established
- Files: All Swift files lack error handling
- Blocks: Robust user experience; crash prevention
- Priority: Medium

**Navigation:**
- Problem: No navigation structure; app has single view
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus/ContentView.swift`
- Blocks: Multi-screen app development
- Priority: High

**Data Layer:**
- Problem: No data persistence, networking, or state management
- Files: None present
- Blocks: Any feature requiring data storage or API access
- Priority: Medium (depends on app requirements)

**.gitignore:**
- Problem: No version control ignore file
- Files: Missing `.gitignore`
- Blocks: Clean commits; prevents accidental commits of build artifacts
- Priority: High

## Test Coverage Gaps

**No Test Coverage:**
- What's not tested: Entire codebase (0% coverage)
- Files: All Swift files (`/Users/adithyafp_/Projects/surahfocus/surahfocus/*.swift`)
- Risk: Any change can break app unnoticed; refactoring impossible
- Priority: High

**App Launch:**
- What's not tested: App initialization, root view rendering
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus/surahfocusApp.swift`
- Risk: Configuration changes could prevent app from launching
- Priority: High

**UI Components:**
- What's not tested: View rendering, user interactions
- Files: `/Users/adithyafp_/Projects/surahfocus/surahfocus/ContentView.swift`
- Risk: UI changes break visual appearance
- Priority: Medium

---

*Concerns audit: 2026-02-03*
