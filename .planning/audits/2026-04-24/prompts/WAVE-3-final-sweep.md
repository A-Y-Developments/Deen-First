# WAVE 3 — Final sweep

**SERIAL. After Tracks A–E all merged to `main`.**

**Estimated time:** 1–2 hours.
**Depends on:** Tracks A, B, C, D, E all merged.
**Blocks:** nothing.

---

## Copy-paste this prompt into the Wave 3 session

You are executing Wave 3 of the 2026-04-24 audit remediation for the Deen First iOS app. All of Wave 2 (Tracks A, B, C, D, E) has merged to `main`.

Purpose: resolve any integration issues from parallel merges, re-verify the app end-to-end on a physical device, and confirm no audit findings slipped.

Read `.claude/CLAUDE.md` before starting.

### Scope

No new feature work. This wave is verification + cleanup only. Any regression found opens a NEW commit on a new fix branch — do NOT reopen merged track branches.

### Step 1 — Clean pipeline

```
git pull origin main
make clean
make install
make generate
make build
make test
```

All six must pass green. If any fail, diagnose and fix before proceeding — the fix lives in this branch.

### Step 2 — Audit closure pass

Open `.planning/audits/2026-04-24/README.md`. Walk the audit list and confirm each finding is either:
- Closed (implementation landed in Track A/B/C/D/E or Wave 1), OR
- Explicitly deferred with a follow-up ticket, OR
- Negative finding (audit 120 only).

For each audit file that's actually closed, add `status: closed` to its frontmatter. Do NOT close audits you haven't verified.

Specifically verify by grep that these actually shipped:
- 020: `UnblockDurationSelectionView` has call sites now (grep `UnblockDurationSelectionView(`).
- 042: `.disable` case in `PendingChangeService` routes to `applyDisable`, not `applyDelete`.
- 060: `MainTabView` has exactly 4 tabs.
- 097: `Project.swift` main app `dependencies` includes `.target(name: "DeenFirstActivityReport")`.
- 113: `ReciteToUnblockViewModel.swift` is under ~200 lines; `RecitationScoringService.swift` and `AyahSequenceProvider.swift` exist.
- 114: `Session` has `type: SessionType`, not `isUnblockSession: Bool`.

### Step 3 — Physical device verification

DeenFirstActivityReport extension cannot be tested on simulator. On a real device, walk this checklist:

**Dashboard (Wave 1 + Track A integration):**
- [ ] Home tab shows DashboardSummaryCard with real (not zero) values.
- [ ] Tap the card pushes DashboardDetailView.
- [ ] DashboardDetailView renders ALL 5 DeviceActivityReport contexts: DeenScore, ScreenTimeOverview, QuranEngagementToday, QuranVsScreenTime, WeeklyTrend.
- [ ] Weekly Trend shows 7 daily bars — not 1, not zero phantoms.

**Tabs:**
- [ ] 4 tabs rendered (Home, Quran, Blocking, Settings). Settings responds at index 3.
- [ ] No Dashboard tab remains.

**Unblock flow (Track A):**
- [ ] Start a focus session → enter Hard Mode via Blocking tab.
- [ ] Attempt unblock → `UnblockDurationSelectionView` appears (NOT the old `UnblockDurationSheet`).
- [ ] Tier 1 is initially unlocked; Tier 2 and Tier 3 are visually locked.
- [ ] Complete Tier 1 recitation → Tier 2 unlocks.
- [ ] Complete Tier 2 → Tier 3 unlocks.
- [ ] Attempt a 4th tier in the same session → blocked with a "session cap reached" state.
- [ ] HM Tier 3 pass grants 20 minutes (not 15).
- [ ] HM Tier 2 displays dynamic "Ayah N Complete" strings, not hardcoded "Ayah 1 Complete".

**Pending Change + Lock Editing (Track B):**
- [ ] Enable Hard Mode on a rule → confirmation dialog appears disclosing Lock Editing auto-enable.
- [ ] Edit a locked rule → pending change appears with 24h countdown.
- [ ] Wait (or fast-forward device clock via Xcode scheme; note 040 handles this correctly now) → pending apply fires.
- [ ] Disable Hard Mode (locked) → pending applies → verify `isLockEditingEnabled` now false.
- [ ] Delete a locked rule from within edit flow → goes to pending `.disable`; when applied, the rule is DISABLED, NOT DELETED.

**Ayah Pool (Track C):**
- [ ] Open Ayah Pool → add an eligible 10-word ayah → success.
- [ ] Attempt to add a 3-word ayah → rejected with typed error message (not silent).
- [ ] Add ayahs until count > 20 → rejected with "pool full" error.
- [ ] In Normal Mode with empty pool → NO pool-empty nudge.
- [ ] In Hard Mode with empty pool → pool-empty nudge appears.
- [ ] Add an ayah while nudge is shown → nudge dismisses.

**Infra (Track D):**
- [ ] Open Console.app on Mac, filter subsystem `com.aydev.deenfirst`. During normal app use, entries appear from both `ScreenTimeMonitor` and `PendingChange` categories. No raw `print` output remains.
- [ ] Archive build locally → signing succeeds with the unified `DeenFirst ...` profile names.

**Quality (Track E):**
- [ ] Open Quran reading → start recitation → background the app → return → recitation handles the phase cleanly (paused or resumed per implementation decision).
- [ ] SummaryViewModel shows loading state (spinner or skeleton) during initial data load.

**V1 regression check (audit 120 — negative finding verification):**
- [ ] Sign in with Apple works (auth).
- [ ] Emergency unblock works.
- [ ] Daily surah loads.
- [ ] Quran search returns results.
- [ ] Paywall displays correctly for non-premium user.
- [ ] Streak increments on a completed normal session.
- [ ] Streak does NOT increment on an unblock session (Track A regression check).

### Step 4 — Fix anything that fell out

If any checklist item fails:
- Do NOT reopen the merged track branches.
- On THIS Wave 3 branch, add a fix commit with a clear conventional-commit message.
- If the fix is > ~30 LOC or non-obvious, split it into its own PR targeting `main`.

### Step 5 — Audit file frontmatter sweep

For every `NNN-slug.md` under `.planning/audits/2026-04-24/` that IS closed:
- Update frontmatter `status: open` → `status: closed`.
- Do NOT modify any other content.

### Step 6 — Update the README

Edit `.planning/audits/2026-04-24/README.md`:
- At the top, add a "RESOLVED" section dated today, listing the resolution status per area (Dashboard: X/8 closed, Unblock: Y/16 closed, etc.).
- Note any audits NOT closed and why (follow-up ticket reference).

### Acceptance

- All 82 audits are either `status: closed` or have an explicit follow-up ticket referenced.
- `make clean && make install && make generate && make build && make test` green from a clean state.
- All physical-device checklist items pass.
- README resolution section is accurate.

### PR

- Target: `main`.
- Title: `chore(audit): wave 3 final sweep — close 2026-04-24 audit cycle`
- Describe: resolution counts per area, list of any audits deferred with follow-up links, device verification date.
