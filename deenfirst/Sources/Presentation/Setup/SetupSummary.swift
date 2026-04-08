import FamilyControls
import SwiftUI

struct SetupSummary: View {
    @EnvironmentObject private var viewModel: SetupViewModel
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 16) {
                Text("Here's a great blocking setup for you to start")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(.white)
                Text("You can edit this anytime later")
                    .font(.system(.callout, weight: .medium))
                    .foregroundStyle(Color.gray4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.previewAppLimitRule != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("App Limit")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "ADA666"))

                            if let rule = viewModel.previewAppLimitRule {
                                BlockRuleCard(
                                    settingsName: rule.name,
                                    appsCount: rule.applicationTokenData.count,
                                    categoriesCount: rule.categoryTokenData.count,
                                    timeInfo: rule.limitDisplayName ?? "N/A",
                                    daysText: rule.daysDisplayText,
                                    isHardMode: rule.isHardMode,
                                    showUnblockButton: false   // preview only, no unblock action
                                )
                            }
                        }
                        .padding(.top, 32)
                    }

                    if !viewModel.previewtimeLimitRules.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Prayer Times")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "ADA666"))

                            ForEach(viewModel.previewtimeLimitRules) { rule in
                                BlockRuleCard(
                                    settingsName: rule.name,
                                    appsCount: rule.applicationTokenData.count,
                                    categoriesCount: rule.categoryTokenData.count,
                                    timeInfo: rule.timeRangeDisplay ?? "N/A",
                                    daysText: rule.daysDisplayText,
                                    isHardMode: rule.isHardMode,
                                    showUnblockButton: false   // preview only, no unblock action
                                )
                            }
                        }
                        .padding(.top, viewModel.previewAppLimitRule == nil ? 32 : 20)
                    }
                }
            }

            Spacer()

            Button {
                Task {
                    await viewModel.saveSetup()
                    router.reset()
                    router.navigate(to: .mainTabs)
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                            .padding(.trailing, 8)
                    }
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isLoading || !viewModel.hasAnyRules)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .mainBackground()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    SetupSummary()
}