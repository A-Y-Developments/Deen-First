---
id: 119
title: StartView and SetupView are dead code — not referenced anywhere
severity: P3
area: code-quality
status: closed
---

## Problem

`StartView.swift` and `SetupView.swift` (both under `Presentation/FocusSession/`) are not referenced anywhere in the codebase. They are orphaned prototype screens. They also contain:
- Hardcoded color hex `"041315"` (StartView)
- Hardcoded Arabic text inline (StartView)
- `Timer.scheduledTimer` usage (StartView)

## Evidence

```bash
grep -r "StartView\|SetupView" deenfirst/Sources/ --include="*.swift" | grep -v "^Binary"
# → no results (files exist but are unreferenced)
```

Files:
- `deenfirst/Sources/Presentation/FocusSession/StartView.swift`
- `deenfirst/Sources/Presentation/FocusSession/SetupView.swift`

## Solution

Delete both files. Run `make generate` after deletion so Tuist removes them from the compiled sources.

If either is intended for future use, move to a `_drafts/` or `_prototypes/` folder outside the `Sources/` tree so Tuist does not compile it.

## Why

Dead code compiled into the main target adds binary size (minor) and creates confusion about what is and isn't live. More critically, the hardcoded strings and Timer usage in StartView set a bad precedent — future developers may copy the patterns thinking they're approved. Removing dead code is low-risk and high-clarity.
