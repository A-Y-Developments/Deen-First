# Linear V2 Conformance Audit — 2026-05-29

**Question asked:** recheck the V2 features on Linear (DF-1..42, all marked *Done*) against the *current* code — even the done tasks — and report/fix anything wrong.

This is a **feature-conformance** pass (does each Done ticket's acceptance criteria actually exist in code), distinct from the **code-quality** audit in `../2026-04-24/` (which is already revalidated and in good shape). Method: a 9-agent verification workflow (grouped by milestone) read each ticket's verbatim acceptance criteria + the live code, then an adversarial refute pass tried to prove every claimed defect was actually implemented, to kill false positives.

Source of criteria: `tickets.json` (full verbatim descriptions pulled from Linear).

---

## Result summary

| Bucket | Count |
|---|---|
| `implemented` (no defect surfaced — see caveat) | 36 |
| `device-pending` (code correct; only a physical-device run can fully close) | 1 (DF-5) |
| **Real code findings** (code contradicts the ticket criteria) | **3 (DF-16, DF-22, DF-37)** |
| **Ticket-drift** (code intentionally differs; *ticket text* is stale, no code change) | 2 (DF-9, DF-11) |

Headline: **the V2 feature set is largely in good shape.** 3 genuine findings (1×P2 needing a product call, 1×P2 UX, 1×P3), all narrow; no P0/P1 fatal/data-loss defects. 2 "deviations" are deliberate later design decisions whose Linear acceptance criteria were never updated — code is correct, the tickets are stale.

**Caveat on the 36 "implemented":** the adversarial refute pass only tried to *falsify defect claims* — nothing tried to falsify the "implemented" verdicts. So read "36 implemented" as "no defect surfaced in 36," not "36 independently hardened." The 3 findings are the ones hardened by adversarial review.

---

## Per-ticket verdicts

| Ticket | Verdict | Title |
|---|---|---|
| DF-1 | implemented | Add isHardMode + isLockEditingEnabled to ScreenTimeRule |
| DF-2 | implemented | Create PendingRuleChange SwiftData entity |
| DF-3 | implemented | Create AyahPoolItem SwiftData entity |
| DF-4 | implemented | Extend AppGroupConstants with Dashboard V2 keys |
| DF-5 | device-pending | Create DeenFirstActivityReport Xcode target |
| DF-6 | implemented | Duration Selection Screen — Unblock tier picker UI |
| DF-7 | implemented | Tier 1 (5 min) — single ayah unblock flow |
| DF-8 | implemented | Tier 2 (10 min) — sequential two-ayah recitation flow |
| DF-9 | ticket-drift | Tier 3 (15 min) — focus session → unblock trigger |
| DF-10 | implemented | Unblock timer replacement logic — longer wins |
| DF-11 | ticket-drift | Add Dashboard tab (5th tab) and new router routes |
| DF-12 | implemented | Hard Mode toggle in AppLimitView + TimeLimitView |
| DF-13 | implemented | ReciteToUnblockViewModel — Hard Mode logic |
| DF-14 | implemented | Hard Mode tier shifting in Duration Selection Screen |
| DF-15 | implemented | Rule card flame badge when isHardMode = true |
| **DF-16** | **FINDING (P2)** | Hard Mode auto-enables Lock Editing on rule save |
| DF-17 | implemented | PendingChangeService — create, cancel, apply, clock check |
| DF-18 | implemented | ScreenTimeRulesService — lock editing gate on edit/delete/disable |
| DF-19 | implemented | Pending Change Sheet UI |
| DF-20 | implemented | Lock Editing toggle in AppLimitView + TimeLimitView |
| DF-21 | implemented | Rule card pending change indicator (clock icon) |
| **DF-22** | **FINDING (P3)** | Auto-apply expired pending changes on foreground |
| DF-23 | implemented | Push notification — pendingChangeApplied type |
| DF-24 | implemented | Clock manipulation mitigation in PendingChangeService |
| DF-25 | implemented | AyahPoolService — CRUD, max-20 enforcement, word count filter |
| DF-26 | implemented | Ayah Pool management screen UI |
| DF-27 | implemented | Surah picker with ayah checkboxes for pool |
| DF-28 | implemented | Quran tab — My Ayah Pool entry card |
| DF-29 | implemented | ReciteToUnblockViewModel — draw from Ayah Pool when available |
| DF-30 | implemented | DashboardDataWriter service — write Quran data to App Group |
| DF-31 | implemented | Integrate DashboardDataWriter at all write points |
| DF-32 | implemented | DeenScoreCalculator — pure function in Shared/ |
| DF-33 | implemented | Dashboard extension UI — Deen Score section |
| DF-34 | implemented | Dashboard extension UI — Screen Time Overview section |
| DF-35 | implemented | Dashboard extension UI — Quran Engagement Today section |
| DF-36 | implemented | Dashboard extension UI — Quran vs Screen Time + Weekly Trend |
| **DF-37** | **FINDING (P2)** | Dashboard tab host view — thin wrapper with date selector and fallback |
| DF-38 | implemented | Unit tests — DeenScoreCalculator |
| DF-39 | implemented | Unit tests — PendingChangeService |
| DF-40 | implemented | Unit tests — AyahPoolService |
| DF-41 | implemented | Integration tests — Tiered Unblock flows (T1, T2, T3) |
| DF-42 | implemented | Integration tests — Hard Mode + Lock Editing interaction |

DF-43 (physical device testing) and DF-44 (ActivityReport provisioning) remain **Backlog** — legitimately not done, manual/device work, not findings.

---

## Genuine code findings (3)

Detailed Problem/Evidence/Solution/Why in separate files. Status after the user's decisions (2026-05-29): **DF-16 fixed, DF-37 fixed, DF-22 left open** by choice. See "Actions taken" at the bottom.

- **123-disable-hardmode-clears-lock-against-spec.md** — DF-16, P2, **needs product decision**. Code does the *opposite* of the DF-16 spec: applying `.disableHardMode` clears **both** `isHardMode` and `isLockEditingEnabled`, but DF-16 says "Lock Editing does NOT turn off automatically when Hard Mode is turned off." The contradicting behavior came from code-audit finding 043 (an auditor symmetry guess that never checked DF-16). The separate `.disableLockEditing` type corroborates the spec. Here the **code is the likely defect, not the ticket** — it silently weakens the V2 accountability friction. Fix (if DF-16 stands) = remove one line + flip one test assertion.
- **121-blocking-card-stale-after-pending-apply.md** — DF-22, P3. When a pending change auto-applies on app foreground, the Blocking tab card doesn't refresh on that same foreground (stale clock-icon / a deleted rule lingers) until the next refresh trigger. Self-heals on next nav/foreground. Fix touches `PendingChangeService` (lock-editing core) → confirm before fixing.
- **122-dashboard-fallback-message-removed.md** — DF-37, P2. The *uncommitted working-tree* loading-cover change (this session) replaced the persistent "Score loading… Pull down to refresh" fallback the ticket requires with a timed 900ms cover that fades unconditionally — so a silent extension failure after 900ms shows a message-less card. This is the exact tradeoff already raised with the user, and it also reverts previously-audited finding 006 (the `Group { if reportReady } else fallback` pattern) — same root cause. Cleanly reconcilable (persistent message layer behind the report).

---

## Ticket-drift (code correct, Linear acceptance criteria stale — no code change)

These two were flagged "deviates" only because the agents compared live code to the *literal ticket text*. In each case the code intentionally differs due to a **later, documented decision**. The fix is to reconcile the Linear ticket text, not the code. (DF-16 was initially in this bucket too but moved to genuine findings — see 123: its supersession was an auditor guess, not a documented decision.)

### DF-9 — Tier 3 streak
- Ticket says: "session saved to history + streak updated normally."
- Code: session IS saved to history; streak bump is intentionally **skipped** for unblock sessions — `SessionService.swift:145-148` `if !session.type.isUnblock`. Deliberate per **DF-110** (closed audit finding `../2026-04-24/110-streak-incremented-on-unblock-session.md`): "unblock sessions are friction, not habit."
- Action: update DF-9 acceptance criteria to "session saved to history; streak NOT bumped for unblock sessions (DF-110)."

### DF-11 — Dashboard as 5th tab
- Ticket says: "5 tabs visible; order Home/Quran/Blocking/Dashboard/Settings; route `case dashboard`."
- Code: nav intentionally stays **4 tabs** (`MainTabView.swift`), Dashboard lives on Home and opens via the `dashboardDetail` route. Deliberate per closed findings **060/065** and `../2026-04-24/MIGRATION-dashboard-to-home.md` (and the user's standing nav preference).
- Action: update DF-11 acceptance criteria to the shipped 4-tab + `dashboardDetail` design.

_(DF-16 moved to genuine code findings — see finding 123. It is **not** ticket-drift: the contradicting code came from an auditor's symmetry guess, not a documented product decision, and the code is the likely defect.)_

---

## Refute-pass / cross-check notes

- **DF-9** was initially flagged "deviates"; the refute agent correctly identified it as a deliberate supersession (DF-110, streak intentionally skipped for unblock sessions). Reclassified as ticket-drift.
- **DF-11** the refute agent marked "defectIsReal=true" (code genuinely differs from the literal ticket) — but it lacked the nav-design-decision context. Cross-checked against the closed 060/065 findings + the migration doc + the user's standing preference → reclassified as ticket-drift, **not** a code fix.
- **DF-16** the refute agent marked it a false positive ("deliberate per DF-043"), relying *secondhand* on the 043 finding. On reading 043 itself, its rationale is an internal-consistency argument that never reconciled against the DF-16 product spec — so this was over-trusted. Re-promoted to a genuine finding (123): the code contradicts an explicit product criterion. **Lesson: a refute agent citing another audit as "deliberate" is only as good as that audit's own reconciliation — verify the source.**

---

## Notes / constraints during this audit

- Read-only workflow; no code edited by agents.
- Working tree was already dirty (the in-flight Dashboard restyle + a prior peer's MainTabView/AppToBlock/RootView edits). DF-37 concerns the in-flight Dashboard work specifically.
- No commit made.

---

## Actions taken (2026-05-29, per user decisions)

| Finding | Decision | Change | Verified |
|---|---|---|---|
| **DF-16** (123) | Restore spec (lock persists) | `PendingChangeService.swift` `.disableHardMode` no longer clears `isLockEditingEnabled`; `HardModeLockEditingIntegrationTests.swift:327` flipped to assert lock stays ON; prior finding 043 marked **superseded/reverted**. | `make test` RC=0 (all tests pass, no failures) |
| **DF-37** (122) | Fix fallback | Cold-start cover reworded to DF-37's "Score loading… / Pull down to refresh." Discovered the per-section in-process fallbacks already exist in all 5 section views (the real "never blank" guarantee). Residual: total extension-process non-render is undetectable (no API callback) — for device testing. | `make test` RC=0 |
| **DF-22** (121) | Leave open (user choice) | none | — |
| DF-9, DF-11 ticket-drift | Not updating Linear (user choice) | none | — |

Build/test: `make test` exited 0 (xcodebuild runs directly in the recipe; RTK truncated the verbose log but RC is authoritative; zero failure signals). No commit made.
