import FamilyControls
import SwiftUI

struct BlockingTabView: View {
    @StateObject private var viewModel = BlockingTabViewModel()
    @State private var showCreateSheet = false
    @EnvironmentObject var router: Router

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "ADA666")))
            } else if !viewModel.hasApps {
                EmptyBlocksView(showCreateSheet: $showCreateSheet)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    blockedAppsContent
                        .padding(.top)
                }
            }
        }
        .navigationTitle("Blocks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .background {
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateBlockSheet()
                .environmentObject(router)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "041315"))
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
        }
        .onChange(of: router.navigationPath.count) { _, _ in
            Task { await viewModel.loadBlockedApps() }
        }
    }

    private var blockedAppsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.appLimits) { limit in
                Button {
                    router.navigate(to: .editAppLimit(id: limit.id))
                } label: {
                    BlockRuleCard(
                        settingsName: limit.name,
                        appsCount: limit.applicationTokenData.count,
                        categoriesCount: limit.categoryTokenData.count,
                        timeInfo: limit.limitDisplayName ?? "N/A",
                        daysText: limit.daysDisplayText
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            ForEach(viewModel.timeLimits) { limit in
                Button {
                    router.navigate(to: .editTimeLimit(id: limit.id))
                } label: {
                    BlockRuleCard(
                        settingsName: limit.name,
                        appsCount: limit.applicationTokenData.count,
                        categoriesCount: limit.categoryTokenData.count,
                        timeInfo: limit.timeRangeDisplay ?? "N/A",
                        daysText: limit.daysDisplayText
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
//        .padding(.horizontal)
    }
}
