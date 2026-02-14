import SwiftUI
import FamilyControls

struct PaywallView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: PaywallViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 40)

                    // Title
                    VStack(spacing: 8) {
                        Text("Unlock Your Quran Journey")
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Start your free trial, cancel anytime.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 32)

                    // Feature Box
                    VStack(alignment: .leading, spacing: 16) {
                        PaywallPlanFeatureRow(text: "Block distracting apps")
                        PaywallPlanFeatureRow(text: "Track your daily streak")
                        PaywallPlanFeatureRow(text: "Set time limits & schedules")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "ADA666").opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Yearly Plan
                    ZStack(alignment: .topTrailing) {
                        Button {
                            viewModel.selectedPlan = .yearly
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Yearly")
                                        .font(.system(.title, design: .serif))
                                        .italic()
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? Color(hex: "DBDABD") : .white)

                                    Text(viewModel.yearlyPackage?.localizedPriceString ?? "$29.99")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("7-days Free Trial")
                                        .font(.subheadline)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))

                                    Text("$2.49/Mo")
                                        .font(.callout)
                                        .foregroundColor(viewModel.selectedPlan == .yearly ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(viewModel.selectedPlan == .yearly ? Color(hex: "ADA666") : Color(hex: "ADA666").opacity(0.2), lineWidth: viewModel.selectedPlan == .yearly ? 2 : 1)
                            )
                        }

                        // Save 50% label
                        Text("Save 50%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "ADA666"))
                            .foregroundColor(Color(hex: "1A494D"))
                            .rotationEffect(.degrees(5))
                            .offset(x: -24, y: -12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                    // Monthly Plan
                    Button {
                        viewModel.selectedPlan = .monthly
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monthly")
                                    .font(.system(.title, design: .serif))
                                    .italic()
                                    .foregroundColor(viewModel.selectedPlan == .monthly ? Color(hex: "DBDABD") : .white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("3-days Free Trial")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.selectedPlan == .monthly ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))

                                Text(viewModel.monthlyPackage?.localizedPriceString ?? "$4.99/Mo")
                                    .font(.callout)
                                    .foregroundColor(viewModel.selectedPlan == .monthly ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(viewModel.selectedPlan == .monthly ? Color(hex: "ADA666") : Color(hex: "ADA666").opacity(0.2), lineWidth: viewModel.selectedPlan == .monthly ? 2 : 1)
                        )
                    }
                    .padding(.horizontal, 24)

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
                    .padding(.horizontal, 24)
                    .padding(.top)

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
                    .padding(.top, 4)

                    Spacer()
                }
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
        router.replaceWith(.screenTimePermission)
    }

    @MainActor
    private func navigateAfterRestore() async {
        router.replaceWith(.screenTimePermission)
    }
}

// MARK: - Supporting Views

private struct PaywallPlanFeatureRow: View {
    var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .foregroundColor(Color(hex: "ADA666"))

            Text(text)
                .foregroundColor(Color(hex: "DBDABD"))
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
