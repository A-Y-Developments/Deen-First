import SwiftUI
import FamilyControls

struct PaywallView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: PaywallViewModel

    var body: some View {
        ZStack {
            // Background gradient
            Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

            ScrollView {
                VStack {
                    Spacer().frame(height: 86)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unlock Your Quran Journey")
                            .font(.system(.largeTitle))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Text("Surah Focus is your way to a better relationship with your faith. Start your free trial, cancel anytime.")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary400)
                            .font(.subheadline)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Feature Box
                    VStack(alignment: .leading, spacing: 4) {
                        PaywallPlanFeatureRow(text: "Block distracting apps")
                        PaywallPlanFeatureRow(text: "Track your daily streak")
                        PaywallPlanFeatureRow(text: "Set time limits & schedules")
                        PaywallPlanFeatureRow(text: "Listen Quran with Focus Session")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.secondary400.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.top, 24)

                    // Yearly Plan
                    ZStack(alignment: .topTrailing) {
                        Button {
                            viewModel.selectedPlan = .yearly
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Yearly")
                                        .font(.system(.title))
                                        .fontWeight(.bold)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? .black : Color.gray4)

                                    Text(viewModel.yearlyPackage?.localizedPriceString ?? "$29.99")
                                        .fontWeight(.medium)
                                        .font(.title3)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? .black : Color.gray4)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 16) {
                                    Text("7-days Free Trial")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? .black : Color.gray4)

                                    Text("$2.49/Mo")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? .black : Color.gray4)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(viewModel.selectedPlan == .yearly ? Color.secondary200 : Color.primary500.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        Color.primary500.opacity(0.4),
                                        lineWidth: 2
                                    )
                            )
                        }

                        // Save 50% label
                        Text("Save 50%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(5))
                            .offset(x: -24, y: -12)
                    }
                    .padding(.top, 40)

                    // Monthly Plan
                    Button {
                        viewModel.selectedPlan = .monthly
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Monthly")
                                    .font(.system(.title2))
                                    .fontWeight(.bold)
                                    .foregroundColor(
                                        viewModel.selectedPlan == .monthly
                                        ? .black
                                        : Color.gray4
                                    )
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 16) {
                                Text("3-days Free Trial")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        viewModel.selectedPlan == .monthly
                                        ? .black
                                        : Color.gray4
                                    )

                                Text("$4.99/Mo")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        viewModel.selectedPlan == .monthly
                                        ? .black
                                        : Color.gray4
                                    )
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    viewModel.selectedPlan == .monthly
                                    ? Color.secondary200
                                    : Color.primary500.opacity(0.4)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    Color.primary500.opacity(0.4),
                                    lineWidth: 2
                                )
                        )
                    }
                    .padding(.top)

                    // CTA Button
                    Button {
                        Task {
                            if await viewModel.purchase() {
                                await navigateAfterPurchase()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Start My Free Trial")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.top, 64)

                    // Restore
                    Button {
                        Task {
                            if await viewModel.restorePurchases() {
                                await navigateAfterRestore()
                            }
                        }
                    } label: {
                        Text("Restore purchase")
                            .font(.footnote)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            await viewModel.loadOfferings()
        }
    }

    @MainActor
    private func navigateAfterPurchase() async {
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            router.replaceWith(.setupAppToBlock)
        } else {
            router.replaceWith(.permissionSetup)
        }
    }

    @MainActor
    private func navigateAfterRestore() async {
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            router.replaceWith(.setupAppToBlock)
        } else {
            router.replaceWith(.permissionSetup)
        }
    }
}

// MARK: - Supporting Views

private struct PaywallPlanFeatureRow: View {
    var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .foregroundColor(Color.secondary200)

            Text(text)
                .foregroundColor(Color.secondary200)
                .font(.callout)

            Spacer()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(Router())
        .environmentObject(PaywallViewModel())
}
