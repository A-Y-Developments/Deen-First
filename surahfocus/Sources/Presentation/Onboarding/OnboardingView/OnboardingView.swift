import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: OnboardingViewModel

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

            VStack(spacing: 0) {
                // Header
                HStack {
                    if viewModel.canGoBack {
                        Button(action: viewModel.goBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    Text(viewModel.progressText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    if viewModel.currentStep < 3 {
                        Button("Skip") {
                            viewModel.skip()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    } else {
                        // Invisible spacer for alignment
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.clear)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingStep1View()
                        .tag(0)
                    OnboardingStep2View()
                        .tag(1)
                    OnboardingStep3View()
                        .tag(2)
                    OnboardingStep4View()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Continue Button
                Button {
                    if viewModel.currentStep == 3 {
                        Task {
                            await viewModel.complete()
                            router.navigate(to: .paywall)
                        }
                    } else {
                        viewModel.goNext()
                    }
                } label: {
                    HStack {
                        if viewModel.isCompleting {
                            ProgressView()
                                .tint(.white)
                            Text("Saving...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        viewModel.canContinue ?
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(!viewModel.canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            viewModel.loadSavedSurvey()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(Router())
        .environmentObject(OnboardingViewModel())
}
