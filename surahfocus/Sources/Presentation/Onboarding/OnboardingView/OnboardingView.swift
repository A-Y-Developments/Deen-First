import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: OnboardingViewModel
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack {
                    // Navigation
                    if viewModel.currentStep < 3 {
                        HStack {
                            if viewModel.canGoBack {
                                Button(action: viewModel.goBack) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                            Button("Skip") {
                                viewModel.skip()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            
                        }
                    }
                    
                    // Indicator
                    if viewModel.currentStep < 3 {
                        HStack(spacing: 6) {
                            ForEach(0..<viewModel.totalSteps-1, id: \.self) { index in
                                Rectangle()
                                    .fill(index < viewModel.currentStep + 1 ? Color.white : Color.white.opacity(0.2))
                                    .frame(height: 4)
                                    .frame(maxWidth: .infinity)
                                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 36)
                
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
                
                // Next Button
                Button {
                    if viewModel.currentStep == 3 {
                        Task {
                            await viewModel.complete()
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
                                .foregroundStyle(viewModel.canContinue ? Color.black : Color.white)
                        } else {
                            Text("Next")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(viewModel.canContinue ? Color.black : Color.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        viewModel.canContinue ? Color.white : Color(hex: "031315")
                    )
                    .cornerRadius(16)
                }
                .disabled(!viewModel.canContinue)
                .clipShape(Capsule())
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
