# WAVE 0 — Pre-flight commit

**Run this ONCE on `main` before creating any Wave 1 / Wave 2 branches.**

**Estimated time:** 5 minutes.
**Blocks:** Wave 1 and every Wave 2 track (they all need to fork from this commit).

---

## Copy-paste this prompt into the Wave 0 session

You are executing Wave 0 of the 2026-04-24 audit remediation for the Deen First iOS app. Read `.claude/CLAUDE.md` first — follow the project rules (Tuist, architecture layers, commit format) for every action.

The working tree on `main` currently has two dirty files:
- `Project.swift` — contains P0 fixes for audits 001, 090, 097 (extension product type + embedding the ActivityReport extension in the main app). Must be committed.
- `deenfirst/Sources/Presentation/Components/PrimaryButton.swift` — UI polish that belongs with Wave 1. Must NOT ride along with this Wave 0 commit.

Your job is one surgical commit.

### Steps

1. Confirm the dirty set is exactly those two files and nothing else:
   ```
   git status
   git diff --stat HEAD
   ```
   Expected output: `Project.swift` and `PrimaryButton.swift` only. If anything else is dirty, STOP and tell me before proceeding.

2. Read the uncommitted Project.swift diff to verify it matches the audit-described fixes:
   ```
   git diff HEAD -- Project.swift
   ```
   You should see:
   - `.appExtension` → `.extensionKitExtension`
   - `NSExtension` block replaced with `EXAppExtensionAttributes` block
   - `.target(name: "DeenFirstActivityReport")` added to main-app dependencies
   - Profile name changes `Deen First ...` → `DeenFirst ...` (partial — Track D finishes the rest)
   - App version bump `1.0.0` → `1.1.0`

3. Stage `Project.swift` ONLY and commit. Do NOT use `git commit -am`.
   ```
   git add Project.swift
   git commit -m "fix(tuist): switch ActivityReport to extensionKitExtension + embed in main app"
   ```

4. Verify `PrimaryButton.swift` is still dirty:
   ```
   git status
   ```
   Expected: `Changes not staged for commit: PrimaryButton.swift`.

5. Regenerate the Xcode project and build to confirm the commit is green:
   ```
   make generate
   make build
   ```
   If `make build` fails, do NOT push. Diagnose first. Likely: SDK/entitlement missing — Track D will pick those up, but Wave 0 must at least generate and compile.

6. Do NOT push yet. Wave 1 will branch from this commit and push together.

### Audits closed by this wave

- `001-extension-product-type.md` (P0)
- `090-activity-report-extension-identifier.md` (P0)
- `097-activity-report-missing-dependency-on-main-app.md` (P0)
- Partial: `091-shield-profile-name-inconsistency.md` (Track D finishes)
- Partial: `092-app-main-profile-name-with-space.md` (Track D finishes)

### Do NOT

- Do not stage or commit PrimaryButton.swift.
- Do not run `git commit -am`.
- Do not push.
- Do not edit Project.swift further — the working-tree diff is the intended fix as-is.
- Do not create a new branch. This commit lands directly on `main` as the baseline for every downstream branch.

### Done when

`git log -1 --stat` shows a single commit touching only `Project.swift`, and `git status` still lists `PrimaryButton.swift` as unstaged.
