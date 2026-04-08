import SwiftUI

struct PendingChangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let rule: ScreenTimeRule
    let changeType: PendingChangeType
    let existingPendingChange: PendingRuleChange?
    let onConfirm: () async -> Void
    let onCancelExisting: () async -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Change Requested")
                .font(.system(.title2, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top)

            if let existing = existingPendingChange {
                existingChangeContent(existing)
            } else {
                newChangeContent
            }

            Spacer()
        }
        .padding(24)
        .background(Color.primary900)
    }

    // MARK: - New pending change state

    private var newChangeContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                subtitle: "Lock Editing is active. This change will apply in 24 hours.",
                appliesAt: Date().addingTimeInterval(PendingRuleChange.applyDelaySeconds),
                changeLabel: changeLabel(for: changeType)
            )

            PrimaryButton(title: "Confirm Request", isLoading: isLoading) {
                Task {
                    isLoading = true
                    await onConfirm()
                    // Sheet dismissal driven by ViewModel setting pendingChangeSheetRule = nil.
                    isLoading = false
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
        }
    }

    // MARK: - Existing pending change state

    private func existingChangeContent(_ change: PendingRuleChange) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                subtitle: "A pending change already exists for this rule.",
                appliesAt: change.appliesAt,
                changeLabel: changeLabel(for: PendingChangeType(rawValue: change.changeType) ?? changeType)
            )

            PrimaryButton(title: "Cancel Pending Change", isLoading: isLoading) {
                Task {
                    isLoading = true
                    await onCancelExisting()
                    // Sheet dismissal driven by ViewModel setting pendingChangeSheetRule = nil.
                    isLoading = false
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Dismiss")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
        }
    }

    // MARK: - Shared info card

    private func infoCard(subtitle: String, appliesAt: Date, changeLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            Text("Applies at: \(appliesAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundColor(Color.secondary400)

            Text(changeLabel)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary500.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func changeLabel(for type: PendingChangeType) -> String {
        switch type {
        case .delete:
            return "Delete rule: \(rule.name)"
        case .edit:
            return "Edit rule: \(rule.name)"
        case .disable:
            return "Disable rule: \(rule.name)"
        case .disableHardMode:
            return "Disable Hard Mode: \(rule.name)"
        case .disableLockEditing:
            return "Disable Lock Editing: \(rule.name)"
        }
    }
}
