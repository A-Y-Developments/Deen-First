import SwiftUI
import FamilyControls

struct PaywallView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: PaywallViewModel

    var isFromSettings: Bool = false   // 👈 new
    var currentPlan: String? = nil     // 👈 new

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Unlock Your Quran Journey")
                    .font(.system(.largeTitle))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Text("Deen First is your way to a better relationship with your faith. Start your free trial, cancel anytime.")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary400)
                    .padding(.top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
                            if let badge = viewModel.trialBadgeText(for: .yearly) {
                                Text(badge)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.selectedPlan == .yearly ? .black : Color.gray4)
                            }

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
                            .stroke(Color.primary500.opacity(0.4), lineWidth: 2)
                    )
                }

                Text("4 Months free!")
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
                            .foregroundColor(viewModel.selectedPlan == .monthly ? .black : Color.gray4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 16) {
                        if let badge = viewModel.trialBadgeText(for: .monthly) {
                            Text(badge)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.selectedPlan == .monthly ? .black : Color.gray4)
                        }

                        Text("$4.99/Mo")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.selectedPlan == .monthly ? .black : Color.gray4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(viewModel.selectedPlan == .monthly ? Color.secondary200 : Color.primary500.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary500.opacity(0.4), lineWidth: 2)
                )
            }
            .padding(.top)

            Spacer()

            // CTA Button
            Button {
                // 👇 Don't do anything if they tap on their current plan
                guard !viewModel.isSelectedPlanCurrent else { return }
                Task {
                    if await viewModel.purchase() {
                        navigateAfterPurchase()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(viewModel.ctaButtonLabel)
                            .font(.headline)
                            .foregroundColor(viewModel.isSelectedPlanCurrent ? Color.white.opacity(0.5) : .black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isSelectedPlanCurrent ? Color.white.opacity(0.3) : Color.white)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isLoading || viewModel.isSelectedPlanCurrent) // 👈 disable if current

            Button {
                Task {
                    if await viewModel.restorePurchases() {
                        navigateAfterRestore()
                    }
                }
            } label: {
                Text("Restore purchase")
                    .font(.callout)
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 20)
        .mainBackground()
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            viewModel.currentActivePlan = currentPlan // 👈 inject before loading
            await viewModel.loadOfferings()
        }
        .navigationBarBackButtonHidden(isFromSettings ? false : true)
    }

    // MARK: - Navigation

    @MainActor
    private func navigateAfterPurchase() {
        if isFromSettings {
            router.navigateBack()  // pop to SubscriptionView, onAppear reloads it
        } else {
            NotificationCenter.default.post(name: .didPurchaseSubscription, object: nil)
        }
    }

    @MainActor
    private func navigateAfterRestore() {
        if isFromSettings {
            router.navigateBack()
        } else {
            NotificationCenter.default.post(name: .didPurchaseSubscription, object: nil)
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
