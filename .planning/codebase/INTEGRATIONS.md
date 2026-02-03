# External Integrations

**Analysis Date:** 2026-02-03

## APIs & External Services

**Quran Data:**
- Not yet integrated - planned per PRD
- SDK/Client: TBD
- Auth: None required for public Quran data

**Audio/Streaming:**
- Not yet integrated - planned for recitation playback
- SDK/Client: TBD
- Auth: None required

## Data Storage

**Databases:**
- None (local iOS app with in-memory state)

**File Storage:**
- Local filesystem only (iOS app bundle and documents directory)

**Caching:**
- None (to be implemented for Quran text, audio, images)

## Authentication & Identity

**Auth Provider:**
- None (local app without user accounts - planned for future phases)

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Console output (Xcode debugger)

## CI/CD & Deployment

**Hosting:**
- App Store (Apple App Store distribution)

**CI Pipeline:**
- None configured

## Environment Configuration

**Required env vars:**
- None (project uses build settings and Info.plist generation)

**Secrets location:**
- Not applicable (no external integrations requiring secrets yet)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Framework Integration Points

**SwiftUI:**
- Native iOS framework (no external SDK)
- Views: `/Users/adithyafp_/Projects/surahfocus/surahfocus/ContentView.swift`
- App entry: `/Users/adithyafp_/Projects/surahfocus/surahfocus/surahfocusApp.swift`

**Asset Catalog:**
- Native iOS asset management
- Location: `/Users/adithyafp_/Projects/surahfocus/surahfocus/Assets.xcassets/`

---

*Integration audit: 2026-02-03*
