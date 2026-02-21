import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = SubscriptionViewModel()

    var body: some View {
        VStack(spacing: 28) {
            Image("app-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 100)

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxHeight: .infinity)
            } else if viewModel.isPremium {
                premiumContent
            } else {
                freeContent
            }

            Spacer()
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background {
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)  // keeps text white
        .onAppear { Task { await viewModel.load() } }
    }

    // MARK: - Premium State
    private var premiumContent: some View {
        VStack(spacing: 28) {
            Text("MashaAllah\nyou're the premium one")
                .font(.system(.title3, weight: .semibold))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(Color.secondary200)

            VStack(spacing: 16) {
                HStack {
                    Text("Your Plan")
                        .foregroundColor(.white)
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.planLabel)
                        .foregroundColor(Color.secondary300)
                        .font(.callout)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary700, lineWidth: 2)
                )

                if !viewModel.renewalText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Renewal")
                            .foregroundColor(.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                        Text(viewModel.renewalText)
                            .foregroundColor(Color.gray4)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary700, lineWidth: 2)
                    )
                }

                explorePlansButton
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Free State
    private var freeContent: some View {
        VStack(spacing: 28) {
            Text("You're on the free plan")
                .font(.system(.title3, weight: .semibold))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(Color.secondary200)

            VStack(spacing: 16) {
                HStack {
                    Text("Your Plan")
                        .foregroundColor(.white)
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Free")
                        .foregroundColor(Color.secondary300)
                        .font(.callout)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary700, lineWidth: 2)
                )

                explorePlansButton
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Shared
    private var explorePlansButton: some View {
        Button {
            router.navigate(to: .paywall(
                isFromSettings: true,
                currentPlan: viewModel.currentPlanType  // 👈 pass active plan
            ))
        } label: {
            HStack {
                Text("Explore Plans")
                    .foregroundColor(.white)
                    .font(.callout)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(Color.primary700)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(Router())
}