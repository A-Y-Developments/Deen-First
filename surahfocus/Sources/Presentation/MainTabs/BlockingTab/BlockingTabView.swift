import FamilyControls
import SwiftUI

struct CircularPlusButton: View {
    var action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 40)
                }
                .buttonStyle(.glass)
            } else {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 40)
                        .background(circleBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }

    @ViewBuilder
    private var circleBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .glassEffect(.regular.interactive())
        } else {
            Circle()
                .fill(.ultraThinMaterial)
        }
    }
}

struct BlockingTabView: View {
    @EnvironmentObject private var viewModel: BlockingTabViewModel
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @EnvironmentObject var router: Router
    @State private var showCreateSheet = false

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.secondary400))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.hasApps {
                    EmptyBlocksView(showCreateSheet: $showCreateSheet)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        blockedAppsContent
                            .padding(.top)
                    }
                    .padding()
                }
            }
        }
        .mainBackground()
        .sheet(isPresented: $showCreateSheet) {
            CreateBlockSheet()
                .environmentObject(router)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.primary900)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            Task { await viewModel.loadBlockedApps() }
            viewModel.syncCountdownFromStorage()
        }
        .onChange(of: router.navigationPath.count) { _, newCount in
            Task { await viewModel.loadBlockedApps() }
            // User returned from ReciteToUnlock — pick up any new per-rule expiry
            viewModel.syncCountdownFromStorage()
        }
    }

    private var customHeader: some View {
        HStack {
            Text("Blocks")
                .font(.system(size: 34, weight: .bold))
            Spacer()
            CircularPlusButton(action: { showCreateSheet = true })
        }
        .padding(.horizontal, 16)
        .padding(.top)
        .padding(.bottom, 8)
    }

    private var blockedAppsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.appLimits) { limit in
                BlockRuleCard(
                    settingsName: limit.name,
                    appsCount: limit.applicationTokenData.count,
                    categoriesCount: limit.categoryTokenData.count,
                    timeInfo: limit.limitDisplayName ?? "N/A",
                    daysText: limit.daysDisplayText,
                    showUnblockButton: viewModel.isRuleCurrentlyBlocking(limit),
                    onUnblock: {
                        // Set the target rule BEFORE navigating so ReciteToUnblockViewModel
                        // knows which rule's shields to remove on a successful recitation.
                        reciteToUnblockViewModel.targetRuleId = limit.id
                        router.navigate(to: .reciteToUnlock)
                    },
                    countdownDisplay: viewModel.countdownDisplay(for: limit.id)
                )
                .onTapGesture {
                    router.navigate(to: .editAppLimit(id: limit.id))
                }
            }

            ForEach(viewModel.timeLimits) { limit in
                BlockRuleCard(
                    settingsName: limit.name,
                    appsCount: limit.applicationTokenData.count,
                    categoriesCount: limit.categoryTokenData.count,
                    timeInfo: limit.timeRangeDisplay ?? "N/A",
                    daysText: limit.daysDisplayText,
                    showUnblockButton: viewModel.isRuleCurrentlyBlocking(limit),
                    onUnblock: {
                        reciteToUnblockViewModel.targetRuleId = limit.id
                        router.navigate(to: .reciteToUnlock)
                    },
                    countdownDisplay: viewModel.countdownDisplay(for: limit.id)
                )
                .onTapGesture {
                    router.navigate(to: .editTimeLimit(id: limit.id))
                }
            }
        }
    }
}