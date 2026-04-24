---
id: 093
title: NSSpeechRecognitionUsageDescription — likely NOT required
severity: P3
area: infra
status: reviewed-false-positive
---

## Problem

Originally flagged as P1 missing plist key. On review: **likely a false positive.**

`NSSpeechRecognitionUsageDescription` is required ONLY when the app uses Apple's `Speech` framework (e.g. `SFSpeechRecognizer`). Deen First does not:

```
$ grep -rn "SFSpeechRecognizer\|import Speech" deenfirst/Sources/
# (no matches)
```

Deen First records audio with `AVAudioRecorder` and uploads the file to OpenAI Whisper over HTTP. This workflow only requires `NSMicrophoneUsageDescription`, which IS present (`Project.swift:40-41`).

## Evidence

- `Project.swift:40-41` has `NSMicrophoneUsageDescription` ✓
- No `Speech` framework imports in Sources
- `callWhisperAPI` at `ReciteToUnblockViewModel.swift:424` sends a multipart upload to `api.openai.com` — no Apple speech API in the stack

## Solution

No plist change needed. **Do not add the key** — adding it would prompt an unnecessary App Review question about speech recognition the app is not doing.

If in the future the app adopts `SFSpeechRecognizer` for on-device transcription, add the key then.

## Why

App Store guideline 5.1.1 requires usage descriptions for frameworks the app actually uses. Whisper over HTTP is treated as generic network audio upload, not speech recognition from iOS's permission perspective. Microphone permission alone is sufficient. This was author error — apologies for the false alarm.
