import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // App Name & Tagline
                VStack(spacing: 8) {
                    Text("Surah Focus")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Block Apps, Build Quran Habits")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Sign in with Apple Button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        if let user = await viewModel.handleSignIn(result: result) {
                            await navigateUser(user)
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 32)
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            // Check if user already signed in
            if let user = await viewModel.getCurrentUser() {
                await navigateUser(user)
            }
        }
    }

    @MainActor
    private func navigateUser(_ user: User) async {
        // Check onboarding FIRST, then subscription
        if !user.hasCompletedOnboarding {
            router.replaceWith(.onboarding)
            return
        }

        // Onboarding complete, check subscription
        let isPremium = (try? await DIContainer.shared.subscriptionService.checkSubscriptionStatus()) ?? false
        if !isPremium {
            router.replaceWith(.paywall)
        } else {
            router.replaceWith(.screenTimePermission)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(Router())
        .environmentObject(AuthViewModel())
}
