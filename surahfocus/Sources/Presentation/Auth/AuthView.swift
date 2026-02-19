import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: AuthViewModel

    var body: some View {
        VStack {
            HStack {
                Image("app-logo")
                Spacer()
            }
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
            Spacer()

            VStack(alignment: .leading, spacing: 40) {
                Text("Hi, there!")
                    .foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text("Welcome to Deen First")
                        .font(.system(.title, weight: .bold))
                        .foregroundStyle(Color.secondary200)
                    Text("Your new way for a better relationship with Allah")
                        .font(.system(.subheadline, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.secondary200)
                        .padding(.top, 8)
                }
                Text("Block apps, build better Quran habits")
                    .foregroundStyle(.white)
                    .font(.footnote)
            }

            Spacer()
            
            VStack(spacing: 28) {
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
                    .foregroundStyle(.white)
                    .font(.caption.weight(.regular))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 48)
        .background {
            Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
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
