import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "020c0e"), location: 0.5),
                    .init(color: Color(hex: "020c0e"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
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
                        .font(.system(.title, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "ADA666"))

                    Text("Block Apps, Build Quran Habits")
                        .font(.system(.callout))
                        .foregroundColor(Color(hex:"DBDABD"))
                }

                Spacer()

                // Sign in with Apple Button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        _ = await viewModel.handleSignIn(result: result)
                        NotificationCenter.default.post(name: .didSignIn, object: nil)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .disabled(viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                
                Text("Terms of Service • Privacy")
                    .foregroundStyle(Color(hex: "8E8E93"))
                    .font(.caption.weight(.regular))
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(Router())
        .environmentObject(AuthViewModel())
}
