---
id: 046
title: PendingChangeType enum has 5 cases but domain.md documents only 2
severity: P3
area: lock-editing
status: closed
---

## Problem

`PendingRuleChange.swift` defines `PendingChangeType` with 5 cases: `edit`, `delete`, `disable`, `disableHardMode`, `disableLockEditing`. The domain reference (`rules/domain.md`) documents only `editRule` and `disableLockEditing` — and uses different names (`editRule` vs `edit`). This mismatch misleads agents writing tests or new features.

## Evidence

`Domain/Entities/PendingRuleChange.swift`:
```swift
enum PendingChangeType: String, Codable {
    case edit
    case delete
    case disable
    case disableHardMode
    case disableLockEditing
}
```

`rules/domain.md` Key Enums section:
```
PendingChangeType: editRule · disableLockEditing (others TBD)
```

Name mismatch: `editRule` in docs vs `edit` in code.

## Solution

Update `rules/domain.md` to reflect the actual enum:
```
PendingChangeType: edit · delete · disable · disableHardMode · disableLockEditing
```

## Why

Documentation drift causes agent confusion and wrong test setup. Low-effort fix; no code change required.
