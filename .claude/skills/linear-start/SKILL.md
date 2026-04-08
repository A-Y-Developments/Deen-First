---
name: linear-start
description: Deen First Linear ticket workflow. Fetches ticket, runs dependency pre-flight, explores code, creates branch, routes to correct domain agent, opens PR. Overrides global linear-start for this project.
---

# /linear-start — Deen First Ticket Workflow

Ticket ID: `$ARGUMENTS`

---

## ⚠️ Anti-hallucination rules — read first

- Never infer, recall, or fabricate ticket data. Everything must come from Linear MCP.
- After fetching, output the raw title, status, labels, and description before doing anything else.
- If Linear MCP is unavailable or returns an error — STOP. Report: "Linear MCP unavailable. Cannot proceed."

---

## Step 1 — Fetch ticket

Make two MCP calls in parallel immediately:
1. `get_issue(id: "$ARGUMENTS", includeRelations: true)` — title, description, acceptance criteria, labels, priority, milestone, relations
2. `list_comments(issueId: "$ARGUMENTS")` — clarifications or decisions

Output now:
```
Ticket: <ID> — <title>
Status: <status>
Labels: <labels>
Description:
<description text>
Relations: <blocked_by entries if any>
```

Do not proceed until this is shown.

---

## Step 2 — Dependency pre-flight ⛔

**Never skip.**

### 2a. Extract blockers
- From `relations`: entries where `type == "blocked_by"` → collect `relatedIssue.identifier`
- From the **fetched** description text: any `DF-\d+` patterns
- Union both sets

### 2b. Fetch all dependency statuses in parallel
Call `get_issue` for each dep simultaneously.

### 2c. Classify

| Status | Classification |
|---|---|
| Done / Completed / Cancelled | ✅ Clear |
| In Progress | ⚠️ Warn |
| Backlog / Todo / Unstarted | ⛔ Blocked |

### 2d. Decide

**⛔ Any blocked deps → STOP:**
```
⛔ BLOCKED — cannot start <ID> until:
  ⛔ <dep-id>  [<status>]  <title>
Finish these first, then re-run.
```

**⚠️ Only in-progress deps → ask user:**
```
⚠️ WARNING — in progress but not done:
  ⚠️ <dep-id>  [In Progress]  <title>
1. Wait (recommended)
2. Proceed anyway
```
Wait for response.

**✅ All clear → proceed.**

---

## Step 3 — Clarify if needed

If description is ambiguous or missing acceptance criteria — list questions and wait. Do not assume.

---

## Step 3b — Mark In Progress

Set ticket status to **In Progress** via Linear MCP **now**, before any code exploration.
This keeps Linear in sync from the moment work begins.

---

## Step 4 — Load project context

Read `.claude/CLAUDE.md`. This is mandatory.

Only read `.claude/context/PROJECT_CONTEXT.md` if the ticket is large, multi-step, or touches cross-cutting concerns (routing, App Group, shared services, Tuist targets). Skip for small, well-scoped tickets.

---

## Step 5 — Explore relevant code

Use grep, glob, and file reads to find all files this ticket will touch.

- Small ticket: read only directly affected files (ViewModel, service, entity, view)
- Large ticket: map all relevant files and dependencies before writing anything

Start narrow, expand only if you find unexpected coupling. Show the user what you found.

---

## Step 6 — Assess scope

| Ticket type | Path |
|---|---|
| Small / well-defined | Implement directly (no plan needed) |
| Large / multi-step | Create a written plan → show user → get approval → implement |
| Unclear | Ask user |

---

## Step 6b — Create task list

After scope is assessed (and plan approved if large), create tasks with `TaskCreate` to track the remaining steps:

- One task per logical implementation unit (e.g. "Add PendingRuleChange entity", "Implement PendingChangeService", "Wire to ScreenTimeRulesService")
- Plus fixed tasks at the end: "QA tests", "Review", "PR + Linear update"

Mark each task **done immediately** when that unit of work completes. Do not batch.

---

## Step 7 — Identify domain role

Use the ticket's **labels** field (from Step 1 MCP response — not title text):

| Label | Domain role | Rules file |
|---|---|---|
| `Agent-iOS` | iOS | `.claude/agents/deenfirst-ios.md` |
| `Agent-Infra` | Infra | `.claude/agents/deenfirst-infra.md` |
| `Agent-QA` | QA | `.claude/agents/deenfirst-qa.md` |
| `Human Touch` | STOP — output checklist, do not automate | — |

Fallback: if no agent label, check title prefix `[iOS]` / `[Infra]` / `[QA]`. If still unclear — ask.

**Read the identified rules file now using the `Read` tool on the exact path** — do not rely on memory or prior context:
- `Agent-iOS` → Read `/Users/adithyafp_/Projects/deenfirst/.claude/agents/deenfirst-ios.md`
- `Agent-Infra` → Read `/Users/adithyafp_/Projects/deenfirst/.claude/agents/deenfirst-infra.md`
- `Agent-QA` → Read `/Users/adithyafp_/Projects/deenfirst/.claude/agents/deenfirst-qa.md`

Internalize its constraints before writing any code. Tell the user which domain role applies and why.

---

## Step 8 — Create branch

```
git checkout -b <type>/df-<number>-<short-slug>
```
- Type from label: `feat`, `fix`, `chore`
- Slug: 2–4 word kebab from ticket title
- Must include the ticket number (e.g. `feature/df-5-hard-mode-toggle`)

---

## Step 9 — Implement

Implement inline in this session using the domain rules loaded in Step 7. You have already read the relevant files and have full project context — no agent spawning needed.

After implementation:
1. Mark implementation task(s) done via `TaskUpdate`
2. Write tests inline for affected files (skip if this is a QA ticket) — apply `.claude/agents/deenfirst-qa.md` rules
3. **Run the tests you just wrote** — execute only the affected test target(s), not the full suite:
   ```bash
   make test
   ```
   If `make test` is unavailable, fall back to:
   ```bash
   xcodebuild test -scheme DeenFirst -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:<TestTargetName>/<TestClassName>
   ```
   - If tests **fail** → fix the implementation or the test (whichever is wrong) → re-run until green
   - If tests **pass** → mark "QA tests" task done
4. Run `/review` on all uncommitted changes
5. After review returns, **immediately and automatically** act on every finding — no user prompt needed:
   - **Must Fix** (bugs, crashes, rule violations) → fix inline
   - **Should Fix / Can Simplify** (quality, redundancy, over-engineering) → run `/simplify` on the affected files
   - Re-run `/review` after all fixes/simplifications until it returns clean
6. Only after a clean review → mark "Review" task done → proceed to Step 10

---

## Step 10 — Build verification

Before opening the PR, verify the code actually compiles. Only errors matter — suppress everything else:

```bash
set -a && . ./.env && set +a && \
xcodebuild -workspace "Deen First.xcworkspace" -scheme "DeenFirst" \
  -configuration Release -destination 'generic/platform=iOS' build \
  2>&1 | grep -E "^.*error:.*$"
```

- No output = build passed → proceed to Step 11
- Any `error:` lines = build failed → read each error, fix the offending code, re-run until silent
- **Never open a PR with a broken build** — this is the final gate before shipping

---

## Step 11 — Commit, push, and open PR

Run `/pr-finish`. Do NOT ask for confirmation — execute immediately.

After PR is created:
- Add PR URL as attachment on the ticket via Linear MCP: `create_attachment(issueId, url, title: "PR")`
- Set ticket status to **In Review** via Linear MCP
- Mark "PR + Linear update" task done

---

## Step 12 — Report

```
✅ <ID> — <title>

Branch:  <branch>
PR:      <URL>
Agent:   <agent used>

What was built:
- <bullet>

Deviations: <any or "none">
Manual steps: <any or "none">
```

---

## Hard constraints

- First action is always the Step 1 MCP fetch — no analysis before real data
- Never skip pre-flight (Step 2)
- Never start while ⛔ blocked tickets exist
- Never implement Human Touch items
- Branch name must include ticket number (df-N)
- Always run `make build` (Step 10) before `/pr-finish` — never skip
- Never open a PR with a failing build or failing tests
- Always run `/pr-finish` at Step 11 — never skip
- Keep ticket status in sync at each major step
- If ticket has no acceptance criteria — ask before building
- If Linear MCP is unavailable — STOP. Do not proceed
- Never run `make generate` skip after any `Project.swift` change
- Never force unwrap — not even in tests
- Never use `print()` in extension targets
