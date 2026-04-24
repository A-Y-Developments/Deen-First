---
id: 027
title: callWhisperAPI uses URLSession.shared directly and force-unwraps URL — two rule violations
severity: P1
area: arch
status: open
---

## Problem

`ReciteToUnblockViewModel.callWhisperAPI()` makes network requests using `URLSession.shared` instead of routing through the project's `HTTPClient`. It also constructs the API URL with `URL(string:)!` (force-unwrap), violating both the no-force-unwrap rule and the architecture rule that all API calls go through `HTTPClient`.

## Evidence

`ReciteToUnblockViewModel.swift` lines 424–483:

```swift
private func callWhisperAPI(audioURL: URL) async throws -> String {
    let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!  // ← force-unwrap
    var request = URLRequest(url: url)
    // ...
    let (data, _) = try await URLSession.shared.data(for: request)  // ← raw URLSession
    // ...
}
```

Project rule (CLAUDE.md): "No force unwrap — ever." and "No direct Whisper/API calls from Views — always goes through ViewModel → Service." By extension, the ViewModel should call a `WhisperService`/`RecitationService` that wraps `HTTPClient`, not make raw URLSession calls itself.

`HTTPClient.swift` exists and is the project's Alamofire wrapper for all network calls. `WhisperAPIDataSource.swift` also exists and should be the layer that handles this.

## Solution

1. Add a `transcribeAudio(fileURL: URL) async throws -> String` method to `WhisperAPIDataSource` (or the existing recitation service).
2. Inject the service into `ReciteToUnblockViewModel` via `DIContainer`.
3. Replace the inline `callWhisperAPI()` body with a call to the injected service.
4. Remove the force-unwrap — the URL is a constant and can be defined safely as a `static let` in the data source.

## Why

Raw `URLSession.shared` usage bypasses authentication headers, timeout configs, retry logic, and logging that `HTTPClient` provides centrally. The force-unwrap on a hardcoded URL is low-risk in practice but sets a bad precedent and violates the project's explicit rule. The existing `WhisperAPIDataSource` was built precisely to own this call.
