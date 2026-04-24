import SwiftUI

struct UnblockDurationSelectionView: View {
    let ruleId: UUID

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @EnvironmentObject private var viewModel: UnblockDurationSelectionViewModel

    var body: some View {
        ZStack {
            Color.primary900
                .ignoresSafeArea()

            VStack(spacing: 24) {
                headerView
                tierCardsView
                Spacer()
                cancelButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadRule(ruleId: ruleId)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Unblocking")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.2)

            Text(viewModel.ruleName.isEmpty ? "..." : viewModel.ruleName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var tierCardsView: some View {
        VStack(spacing: 14) {
            ForEach([UnblockTier.tier1, .tier2, .tier3], id: \.self) { tier in
                TierCardView(
                    tier: tier,
                    isHardMode: viewModel.isHardMode,
                    isLocked: !viewModel.isAvailable(tier),
                    onTap: { selectTier(tier) }
                )
            }
        }
    }

    private var cancelButton: some View {
        Button(action: { router.navigateBack() }) {
            Text("Cancel")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func selectTier(_ tier: UnblockTier) {
        guard viewModel.isAvailable(tier) else { return }
        switch tier {
        case .tier1, .tier2:
            reciteToUnblockViewModel.targetRuleId = ruleId
            reciteToUnblockViewModel.tier = tier
            router.navigate(to: .reciteToUnlock)
        case .tier3:
            router.navigate(to: .focusSection(unlockRuleId: ruleId))
        }
    }
}

// MARK: - TierCardView

private struct TierCardView: View {
    let tier: UnblockTier
    let isHardMode: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isLocked ? 0.04 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(durationLabel)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(isLocked ? 0.4 : 1.0))

                        Text(requirementLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(isLocked ? 0.3 : 0.7))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, isHardMode ? 36 : 0)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.35))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                if isHardMode {
                    Text("🔥")
                        .font(.title3)
                        .padding(12)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private var durationLabel: String {
        // DF-115: read from the canonical UnblockTier source instead of inlining.
        "\(tier.minutes(isHardMode: isHardMode)) min"
    }

    private var requirementLabel: String {
        switch tier {
        case .tier1:
            return isHardMode ? "Recite 2 ayahs (5+ words each)" : "Recite 1 ayah"
        case .tier2:
            return isHardMode ? "Recite 3 ayahs (5+ words each)" : "Recite 2 ayahs"
        case .tier3:
            return isHardMode ? "Complete a 20-min Quran session" : "Complete a 15-min Quran session"
        }
    }
}
