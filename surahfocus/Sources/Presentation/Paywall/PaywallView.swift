import SwiftUI
import FamilyControls

struct PaywallView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: PaywallViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Unlock Your Quran Journey")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Start your free trial, cancel anytime")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "shield.fill", text: "Block distracting apps")
                        FeatureRow(icon: "book.fill", text: "Read Quran with translations")
                        FeatureRow(icon: "speaker.wave.2.fill", text: "Listen to beautiful recitations")
                        FeatureRow(icon: "flame.fill", text: "Track your daily streak")
                        FeatureRow(icon: "clock.fill", text: "Set time limits & schedules")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Build a daily Quran habit")
                    }
                    .padding(.horizontal, 24)

                    // Subscription Plans
                    VStack(spacing: 12) {
                        // Yearly Plan
                        SubscriptionCard(
                            title: "Yearly",
                            price: viewModel.yearlyPackage?.localizedPriceString ?? "$29.99/year",
                            savings: "Save 50%",
                            trial: "7-day free trial",
                            isSelected: viewModel.selectedPlan == .yearly,
                            badge: "RECOMMENDED"
                        ) {
                            viewModel.selectedPlan = .yearly
                        }

                        // Monthly Plan
                        SubscriptionCard(
                            title: "Monthly",
                            price: viewModel.monthlyPackage?.localizedPriceString ?? "$4.99/month",
                            savings: nil,
                            trial: "3-day free trial",
                            isSelected: viewModel.selectedPlan == .monthly,
                            badge: nil
                        ) {
                            viewModel.selectedPlan = .monthly
                        }
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
                                    .tint(.white)
                            } else {
                                Text("Start \(viewModel.trialDurationText) Free Trial")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)

                    // Footer Links
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task {
                                if await viewModel.restorePurchases() {
                                    await navigateAfterRestore()
                                }
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Open terms URL
                            }

                            Text("•")

                            Button("Privacy") {
                                // Open privacy URL
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 40)
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
        // After purchase, always go to screen time permission
        // AuthView guard will handle proper routing on next launch
        router.replaceWith(.screenTimePermission)
    }

    @MainActor
    private func navigateAfterRestore() async {
        // After restore, let AuthView guard handle proper routing
        router.replaceWith(.screenTimePermission)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4facfe"))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let savings: String?
    let trial: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "1a1a2e"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "FFD700"))
                                .cornerRadius(4)
                        }
                    }

                    Text(price)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 8) {
                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "4facfe"))
                        }

                        Text(trial)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                Circle()
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.white.opacity(0.3),
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "4facfe") : Color.clear)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(Router())
        .environmentObject(PaywallViewModel())
}
