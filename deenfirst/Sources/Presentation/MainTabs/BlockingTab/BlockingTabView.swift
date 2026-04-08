import FamilyControls
import SwiftUI
import UIKit

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
    @State private var showUnblockSheet = false
    @State private var pendingUnblockRuleId: UUID? = nil

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
        .sheet(isPresented: $showUnblockSheet) {
            UnblockDurationSheet(ruleId: pendingUnblockRuleId)
                .environmentObject(reciteToUnblockViewModel)
                .environmentObject(router)
                .presentationDetents([.fraction(0.55)])
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
        .onAppear { refreshBlockingState() }
        .onChange(of: router.navigationPath.count) { _, newCount in
            _ = newCount
            refreshBlockingState()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in refreshBlockingState() }
    }

    private func refreshBlockingState() {
        Task { await viewModel.loadBlockedApps() }
        viewModel.syncCountdownFromStorage()
    }

    private var customHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Blocks")
                    .font(.system(size: 34, weight: .bold))
                Text("Build your daily recitation habit")
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
            }
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
                    isHardMode: limit.isHardMode,
                    showUnblockButton: viewModel.isRuleCurrentlyBlocking(limit),
                    onUnblock: {
                        pendingUnblockRuleId = limit.id
                        showUnblockSheet = true
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
                    isHardMode: limit.isHardMode,
                    showUnblockButton: viewModel.isRuleCurrentlyBlocking(limit),
                    onUnblock: {
                        pendingUnblockRuleId = limit.id
                        showUnblockSheet = true
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
