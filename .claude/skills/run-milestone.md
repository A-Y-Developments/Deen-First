---
name: run-milestone
description: Runs a full Deen First milestone in sequence. Fetches all tickets from Linear, resolves execution order, shows the plan, then walks through each ticket one at a time using /linear-start — pausing after each PR for you to review and merge before continuing.
---

# /run-milestone — Deen First Milestone Runner

Milestone: `$ARGUMENTS`

---

## ⚠️ Anti-hallucination rules — read first

- All ticket data MUST come from Linear MCP calls. No exceptions.
- Never infer, recall, or fabricate ticket IDs, titles, statuses, or dependency order from memory.
- If any MCP call fails or returns 0 results — STOP. Report: "MCP returned no data. Cannot proceed."
- After every MCP call, output the raw results before reasoning about them.

---

## Step 1 — Fetch milestone tickets

Call Linear MCP:
```
list_issues(filter: { milestone: { name: { eq: "$ARGUMENTS" } } })
```

Output the raw results now — every ticket ID, title, status, and labels exactly as returned. Do not proceed until this list is shown.

If MCP fails or returns 0 tickets — STOP. Do not guess or fill from memory.

---

## Step 2 — Transition Backlog → Todo

For every ticket from Step 1 that is in `Backlog`, call:
```
save_issue(id: "<real id from Step 1>", state: "Todo")
```

Skip tickets already in `Todo`, `In Progress`, `Done`, or `Cancelled`. Never move backwards.

Then filter: continue only with `Todo` and `In Progress` tickets.

---

## Step 3 — Fetch dependency data

For every remaining ticket, call `get_issue(id, includeRelations: true)` in parallel.

From each response, extract:
- `relations` entries where `type == "blocked_by"` → `relatedIssue.identifier` values
- Any `DF-\d+` pattern found in the **fetched** description text (not memory)

Output the dependency map — list each ticket and its blockers. Do not proceed until this is shown.

---

## Step 4 — Resolve execution order

Build execution order **strictly from the dependency map in Step 3**. Do not use prior knowledge.

Rules (in priority order):
1. Formal `blocked_by` relations — hard constraints
2. DF-xx text references in fetched descriptions — soft ordering hints
3. Domain logic: Infra tickets before iOS tickets that consume their output; entities before services before ViewModels
4. When in doubt — sequential

Parallel groups: only mark tickets as parallel if they have no dependency on each other AND touch completely different file trees. Never parallel if either touches `Project.swift`, `AppGroupConstants.swift`, or shared services.

---

## Step 5 — Present the plan and wait

Output the proposed execution order using **only real ticket IDs and titles from Steps 1–3**:

```
## Milestone: <milestone name from MCP>

Fetched <N> tickets. Execution order:

  Step 1:  <ID>  [<label>]  <title>  → PR, then merge
  Step 2:  <ID>  [<label>]  <title>  → PR, then merge
  Step 3a: <ID>  [<label>]  <title>  ← parallel
  Step 3b: <ID>  [<label>]  <title>  ← parallel

Human Touch (you act, not the agent):
  <ID>  <title>  — reason

Proceed? (yes / adjust)
```

**Wait for explicit user confirmation before executing.**

---

## Step 6 — Execute tickets in order

### For each sequential ticket:

1. `git pull origin main`
2. Run `/linear-start <ticket-id>` — this fetches, explores, implements, and opens the PR
3. After PR is open, pause:
   ```
   ⏸ <ID> — <title>
   PR: <URL>

   Review and merge it, then reply "merged" to continue.
   ```
4. Wait for user to say "merged" (or equivalent)
5. `git pull origin main`
6. Move to next ticket

### For parallel groups:

1. `git pull origin main`
2. Tell the user which tickets will run in parallel and ask them to confirm
3. Run `/linear-start` for ticket A, complete it fully (including PR)
4. Then run `/linear-start` for ticket B, complete it fully (including PR)
   (Note: true parallelism isn't safe in one context — run sequentially but treat as logically parallel)
5. Pause:
   ```
   ⏸ Parallel group done. PRs open:
     <ID-A>: <PR URL>
     <ID-B>: <PR URL>

   Merge both, then reply "merged" to continue.
   ```
6. Wait for confirmation
7. `git pull origin main`

### On failure:

If `/linear-start` reports ⛔ blocked or fails — STOP. Report what failed. Wait for the user to resolve before continuing.

---

## Step 7 — Human Touch tickets

For any ticket labelled `Human Touch`:

```
## Human Touch required — your action needed

### <ID> — <title>
- [ ] <action from ticket description>
- [ ] <action from ticket description>

Reply "done" when complete to continue.
```

Wait for explicit confirmation before proceeding.

---

## Step 8 — Milestone complete

```
✅ <milestone name> — COMPLETE

Completed:
  ✅ <ID>  <title>  PR #N
  ...

Human Touch completed:
  ✅ <ID>  <title>

Skipped (already done):
  <ID>  <title>

Failed / blocked:
  — none
```

---

## Hard constraints

- One ticket = one PR. Never combine.
- Never start the next ticket before the previous PR is confirmed merged.
- Never infer ticket data from memory — all IDs, titles, statuses from MCP only.
- Never fabricate. If MCP fails — STOP.
- Always confirm execution plan before starting.
- Stop immediately on any ⛔ block.
- Human Touch items require explicit user confirmation.
