---
id: 122
title: Dashboard host view cold-start cover lacked the spec'd fallback wording
severity: P2
area: dashboard
ticket: DF-37
status: fixed
note: introduced by uncommitted working-tree change this session; fixed this session
---

## Problem

DF-37 acceptance criterion (marked *Critical*): "Fallback message shown if extension fails: 'Score loading… Pull down to refresh.' — never a blank/black screen."

The uncommitted working-tree `DashboardReportSection` (this session) masks the extension cold-start with a timed 900ms opaque cover that fades unconditionally. The cover showed a generic spinner + "Loading…", not the DF-37 wording, and after it fades there is no main-app message layer.

## Investigation — the "never blank" guarantee actually lives in the extension

A first instinct was to add a persistent fallback message *behind* the `DeviceActivityReport` in the host view. **This is impossible here:** the extension section views render on a transparent background, so any message sharing the frame with the report — behind OR in front — ghosts through the report's transparent regions on a successful render. The only ghosting-free arrangement is mutual exclusion, and the host has no render-success signal (DeviceActivityReport exposes no "rendered" callback), so it cannot represent "failed" vs "rendered".

The correct place for the "never blank" guarantee is **in-process, inside each section view** (an if/else that is mutually exclusive with content by construction). Audit of all five sections confirms this already exists:

- `DeenScoreSectionView` — `else { LoadingPlaceholder(message:) }` ("Score loading…")
- `ScreenTimeOverviewSectionView` — `EmptyState()` "No screen time data yet / Use your phone for a bit and pull to refresh."
- `QuranEngagementSectionView` — `EmptyPlaceholder()` "No data yet"
- `QuranVsScreenTimeSectionView` — `EmptyState()` "No activity yet"
- `WeeklyTrendSectionView` — `EmptyState()` "No trend data yet"

So whenever the extension renders at all, every section shows content or a message — never a blank area. The data-not-ready case (the common one the user actually sees on first run) is fully covered.

## Solution (applied)

Two parts:
1. **In-process per-section fallbacks** — already present in all 5 section views; no change needed. This is the real "never blank" guarantee.
2. **Cold-start cover** (`DashboardDetailView.swift` `loadingPlaceholder`) — updated to carry DF-37's exact wording: "Score loading…" + "Pull down to refresh." (kept the spinner as a cold-start affordance). Applied this session.

## Residual (State D — API-limited, cannot fix)

If the extension *process never renders at all* (total cold failure, not merely "no data"), the host shows the branded card with no message after the 900ms cover fades. This is genuinely undetectable from the host — `DeviceActivityReport` provides no render/failure callback. It will surface only during physical-device testing (DF-43) and its likelihood drops once ActivityReport provisioning (DF-44) lands. Noted, not silently dropped.

## Why

P2: contradicted a criterion the ticket flags as *Critical*. The fix turned out to be small because the substantive guarantee already existed in the extension; the working-tree change had merely swapped the cover wording. Reconciled before the in-flight Dashboard work is committed. (This also relates to previously-audited finding 006 — the original `Group { if reportReady } else fallback` pattern — which the working-tree change replaced.)
