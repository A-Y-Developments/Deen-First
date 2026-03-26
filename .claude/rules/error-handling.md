# Error Handling

## Levels

| Level | Type | Where |
|---|---|---|
| P0 — Fatal | App crash / data corruption | Fix immediately, never suppress |
| P1 — User-visible | Feature fails, user must know | Show in-line error state or alert |
| P2 — Degraded | Feature partially works | Log + fallback gracefully |
| P3 — Silent | Non-critical background failure | Log only |

## Patterns

### ViewModel — loading state pattern
```swift
@Published var isLoading = false
@Published var errorMessage: String?

func loadData() {
    Task {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await service.fetch()
            // update published state
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

### Service — propagate throws
```swift
func applyPendingChanges() async throws {
    let pending = try await repository.fetchDue()
    for change in pending {
        try await repository.apply(change)
    }
}
```

### Repository — wrap SwiftData errors
```swift
func save(_ item: AyahPoolItem) throws {
    do {
        context.insert(item)
        try context.save()
    } catch {
        throw RepositoryError.saveFailed(underlying: error)
    }
}
```

## Rules

1. **No force try (`try!`)** — ever.
2. **No `try?` that silently discards errors** — unless the failure is truly P3 and you log it.
3. **Async/await + do/catch only** — no completion handlers.
4. **Explicit loading states** — every async ViewModel operation sets `isLoading` before and after.
5. **Clock manipulation (PendingChangeService)** — log and skip silently; never surface to user.
6. **Screen Time API errors** — these are P1 in the unblock flow; always surface with a retry option.
7. **Whisper API errors** — P1 during recitation; show retry prompt, don't silently fail the session.

## App Group errors

If `UserDefaults(suiteName:)` returns nil — this is a misconfiguration (P0). Log with `os_log` and fail loudly in debug.

## Extension constraints

Extensions use `os_log` only. Never `print()`. Category: `"DeenFirst"`.
```swift
import os
private let logger = Logger(subsystem: "com.aydev.deenfirst", category: "ActivityReport")
logger.error("Failed to read dashboard data: \(error.localizedDescription)")
```
