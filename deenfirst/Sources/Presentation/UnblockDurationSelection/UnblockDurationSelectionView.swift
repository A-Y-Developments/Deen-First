import SwiftUI

struct UnblockDurationSelectionView: View {
    let ruleId: UUID

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @StateObject private var viewModel = UnblockDurationSelectionViewModel()

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
            TierCardView(
                tier: .tier1,
                isHardMode: viewModel.isHardMode,
                onTap: { selectTier(.tier1) }
            )
            TierCardView(
                tier: .tier2,
                isHardMode: viewModel.isHardMode,
                onTap: { selectTier(.tier2) }
            )
            TierCardView(
                tier: .tier3,
                isHardMode: viewModel.isHardMode,
                onTap: { selectTier(.tier3) }
            )
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
        switch tier {
        case .tier1:
            reciteToUnblockViewModel.targetRuleId = ruleId
            reciteToUnblockViewModel.tier = .tier1
            router.navigate(to: .reciteToUnlock)
        case .tier2:
            reciteToUnblockViewModel.targetRuleId = ruleId
            reciteToUnblockViewModel.tier = .tier2
            router.navigate(to: .reciteToUnlock)
        case .tier3:
            router.navigate(to: .selectSurah(surahs: []))
        }
    }
}

// MARK: - TierCardView

private struct TierCardView: View {
    let tier: UnblockTier
    let isHardMode: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(durationLabel)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(requirementLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, isHardMode ? 36 : 0)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
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
    }

    private var durationLabel: String {
        switch tier {
        case .tier1: return "5 min"
        case .tier2: return "10 min"
        case .tier3: return "15 min"
        }
    }

    private var requirementLabel: String {
        switch tier {
        case .tier1:
            return isHardMode ? "Recite 1 ayah (5+ words)" : "Recite 1 ayah"
        case .tier2:
            return isHardMode ? "Recite 2 ayahs (5+ words each)" : "Recite 2 ayahs"
        case .tier3:
            return "Complete a Quran session"
        }
    }
}
