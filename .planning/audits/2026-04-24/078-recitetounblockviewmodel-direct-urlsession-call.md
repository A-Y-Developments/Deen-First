---
id: 078
title: ReciteToUnblockViewModel calls Whisper API directly via URLSession — bypasses HTTPClient service
severity: P1
area: arch
status: open
---

## Problem

`ReciteToUnblockViewModel.callWhisperAPI(audioURL:apiKey:)` constructs a `URLRequest`, sets auth headers, builds a multipart body, and calls `URLSession.shared.data(for:)` directly inside the ViewModel. This violates CLAUDE.md Hard Rule 7: "No direct Whisper/API calls from Views — always goes through ViewModel → Service."

The project has `WhisperAPIDataSource` and `HTTPClient` already defined for exactly this purpose. The ViewModel bypasses both.

## Evidence

`ReciteToUnblockViewModel.swift:424-473`:
```swift
private func callWhisperAPI(audioURL: URL, apiKey: String) async throws -> String {
    var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    // ... multipart body construction ...
    let (data, response) = try await URLSession.shared.data(for: request)
    // ...
}
```

Called at line 363: `let transcribed = try await callWhisperAPI(audioURL: audioURL, apiKey: apiKey)`

## Solution

Move all of `callWhisperAPI` logic into `WhisperAPIDataSource` (or a new `transcribeAudio(audioURL:)` method on it). Inject the data source via `DIContainer` into the ViewModel and call:

```swift
let transcribed = try await whisperAPIDataSource.transcribe(audioURL: audioURL)
```

The ViewModel should not know about `URLRequest`, multipart encoding, or `URLSession`.

## Why

Rule 7 exists so API call logic (auth headers, multipart encoding, retry, error mapping) is testable in isolation and not duplicated. The current implementation also hardcodes the Whisper endpoint URL inline in the ViewModel, making it impossible to swap without editing Presentation layer code.
