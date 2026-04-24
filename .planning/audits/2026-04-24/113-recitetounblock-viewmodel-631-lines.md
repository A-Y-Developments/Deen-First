---
id: 113
title: ReciteToUnblockViewModel is 631 lines — needs decomposition
severity: P2
area: code-quality
status: open
---

## Problem

`ReciteToUnblockViewModel.swift` is 631 lines and owns: tier state machine, Hard Mode logic, ayah pool selection, pool nudge tracking, Whisper API call, similarity scoring, audio recording lifecycle, shorter-wins guard, and unblock grant. This is a god-object ViewModel that violates single-responsibility and makes the tier state machine untestable in isolation.

## Evidence

File: `deenfirst/Sources/Presentation/ReciteToUnblock/ReciteToUnblockViewModel.swift`
- Lines 1-631 (631 total)
- `processRecitationOutcome` alone spans ~80 lines
- `transcribeAndEvaluate` spans ~60 lines and directly calls URLSession (line 426 — also a force unwrap, see 118)
- Debug prints: lines 176, 377, 378, 381, 382, 385

## Solution

Extract into focused collaborators:

1. **`RecitationScoringService`** — Whisper API call + similarity calculation. Injected, testable, mockable. `ReciteToUnblockViewModel` already accepts `screenTimeService` and `ayahPoolService` via DI — add this.
2. **`AyahSequenceProvider`** — pool vs. standard selection, Hard Mode word-count filter, sequence building. Currently scattered across VM.
3. Keep `ReciteToUnblockViewModel` as the state machine coordinator only: receives scored result, drives `UnblockTier` transitions, calls unblock grant.

This decomposition makes the state machine unit-testable without stub audio or network (as `TieredUnblockIntegrationTests` already does via `processRecitationOutcome` seam — that seam should be the public interface of a thinner VM).

## Why

631-line ViewModels resist change and breed bugs. The V2 tier logic was added on top of existing V1 recitation logic without decomposition, which is why 024, 026, 029, 030, 031 (other audit findings) are all isolated in this one file. Each future tier change requires reading and modifying the entire file. Extraction is the correct fix, not further feature additions in-place.
