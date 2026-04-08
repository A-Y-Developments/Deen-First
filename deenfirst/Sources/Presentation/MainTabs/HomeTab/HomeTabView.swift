import SwiftUI
import UIKit

struct HomeTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: HomeTabViewModel
    @EnvironmentObject var settingsViewModel: SettingsTabViewModel
    @EnvironmentObject var reciteToUnblockViewModel: ReciteToUnblockViewModel

    @State private var showUnblockSheet = false
    @State private var pendingUnblockRuleId: UUID?

    let onViewAllSurahs: (() -> Void)?
    let onViewAllBlocks: (() -> Void)?

    init(onViewAllSurahs: (() -> Void)? = nil, onViewAllBlocks: (() -> Void)? = nil) {
        self.onViewAllSurahs = onViewAllSurahs
        self.onViewAllBlocks = onViewAllBlocks
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                dailySurahSection
                activeBlocksSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .mainBackground()
        .navigationBarHidden(true)
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
        .task {
            await settingsViewModel.loadUserData()
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteSession)) { _ in
            Task {
                await settingsViewModel.loadUserData()
                await viewModel.refreshStreak()
            }
        }
        .onChange(of: router.navigationPath.count) { _, _ in
            Task { await viewModel.loadData() }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task { await viewModel.loadData() }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text("As-salamu alaykum, \(settingsViewModel.displayName.components(separatedBy: " ").first ?? "")!")
                .font(.system(.title2, design: .serif))
                .italic()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(spacing: 4) {
                HStack(spacing: -4) {
                    Image("fire")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56)
                    Text("\(viewModel.currentStreak) day\(viewModel.currentStreak == 1 ? "" : "s")")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(hex: "AEF29B"))
                }
                .padding(.trailing, 16)

                Text(viewModel.currentStreak == 0 ? "Start a new streak" : "Keep your streak going!")
                    .font(.callout)
                    .foregroundStyle(Color(hex: "DBDABD"))
            }

            Button {
                router.navigate(to: .focusSection(unlockRuleId: nil))
            } label: {
                Text("Start Focus Session")
                    .padding(.vertical, 14)
                    .padding(.horizontal, 48)
                    .background(Color.white)
                    .foregroundColor(Color.primary600)
                    .font(.system(.body, weight: .semibold))
                    .clipShape(Capsule())
            }
            .shadow(color: Color.primary400, radius: 12)
            .padding(.top, 8)

            Text("Listen to Quran, reconnect with your Creator,\nand remove all distractions.")
                .font(.callout)
                .foregroundStyle(Color(hex: "DBDABD").opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var dailySurahSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Surah")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    onViewAllSurahs?()
                } label: {
                    Text("View All Surah")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(Color(hex: "AEF29B"))
                }
                .buttonStyle(.plain)
            }

            if viewModel.isLoadingDailySurah && viewModel.dailySurah == nil {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let dailySurah = viewModel.dailySurah {
                DailySurahCard(surah: dailySurah) {
                    router.navigate(to: .quranReading(surahId: dailySurah.number))
                }
            } else {
                Text("Unable to load daily surah")
                    .font(.system(.footnote))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 8)
            }
        }
    }

    private var activeBlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Blocks")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    onViewAllBlocks?()
                } label: {
                    Text("View All Blocks")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(Color(hex: "AEF29B"))
                }
                .buttonStyle(.plain)
            }

            if viewModel.hasBlocks {
                ForEach(viewModel.visibleAppLimits) { limit in
                    BlockRuleCard(
                        settingsName: limit.name,
                        appsCount: limit.applicationTokenData.count,
                        categoriesCount: limit.categoryTokenData.count,
                        timeInfo: limit.limitDisplayName ?? "N/A",
                        daysText: limit.daysDisplayText,
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

                ForEach(viewModel.visibleTimeLimits) { limit in
                    BlockRuleCard(
                        settingsName: limit.name,
                        appsCount: limit.applicationTokenData.count,
                        categoriesCount: limit.categoryTokenData.count,
                        timeInfo: limit.timeRangeDisplay ?? "N/A",
                        daysText: limit.daysDisplayText,
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
            } else {
                EmptyActiveBlocksView()
            }
        }
    }
}
