import Foundation
import ManagedSettings
import FamilyControls

@MainActor
final class ManagedSettingsWrapper {
    let store = ManagedSettingsStore()

    // MARK: - Apply (additive / union)

    /// Adds tokens to the existing shield state without removing anything already shielded.
    ///
    /// FIX: Previously this used assignment (`store.shield.applications = applicationTokens`),
    /// which would OVERWRITE whatever AppLimit or TimeLimit had already set. Now uses union so
    /// multiple sources (AppLimit, TimeLimit, Focus Session) can all contribute to the shield
    /// without clobbering each other.
    func applyShields(
        applicationTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>
    ) {
        if !applicationTokens.isEmpty {
            let existing = store.shield.applications ?? []
            store.shield.applications = existing.union(applicationTokens)
        }

        if !categoryTokens.isEmpty {
            switch store.shield.applicationCategories {
            case .specific(let existing, let except):
                store.shield.applicationCategories = .specific(
                    existing.union(categoryTokens), except: except)
            case .all:
                break // already blocking everything, no-op
            default:
                store.shield.applicationCategories = .specific(categoryTokens, except: [])
            }
        }
    }

    // MARK: - Replace (atomic full-state swap)

    /// Replaces the entire shield state atomically with exactly the given tokens.
    ///
    /// Use this in `reapplyActiveShields` — where we've already computed the full
    /// desired set from ALL active rules — to do a clean swap without a visible gap.
    /// Passing empty sets clears that shield type entirely.
    func replaceShields(
        applicationTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>
    ) {
        store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens

        if categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
        } else {
            store.shield.applicationCategories = .specific(categoryTokens, except: [])
        }
    }

    // MARK: - Remove specific tokens

    /// Removes only the given tokens from the current shield state, leaving everything else intact.
    ///
    /// Use this in `intervalDidEnd` / `intervalDidStart` to remove shields for a specific
    /// rule without wiping shields that belong to other rules or an active session.
    func removeShields(
        applicationTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>
    ) {
        if !applicationTokens.isEmpty {
            let existing = store.shield.applications ?? []
            let remaining = existing.subtracting(applicationTokens)
            store.shield.applications = remaining.isEmpty ? nil : remaining
        }

        if !categoryTokens.isEmpty {
            switch store.shield.applicationCategories {
            case .specific(let existing, let except):
                let remaining = existing.subtracting(categoryTokens)
                store.shield.applicationCategories = remaining.isEmpty
                    ? nil
                    : .specific(remaining, except: except)
            default:
                break
            }
        }
    }

    // MARK: - Remove all

    /// Clears every shield type completely.
    /// Only call this when you are certain nothing else needs to remain shielded
    /// (e.g., subscription expired, all rules deleted).
    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}