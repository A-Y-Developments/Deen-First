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
            Image("quran")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .padding(.vertical, 32)
            Spacer()

            VStack(alignment: .leading, spacing: 40) {
                Text("Hi, there!")
                    .font(.system(.title2, weight: .semibold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text("Welcome to Surah Focus")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(Color.secondary200)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Your new way for a better relationship with Allah")
                        .font(.system(.body, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.secondary200)
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("Block apps, build better Quran habits")
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
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
                .disabled(viewModel.isLoading)
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                
                HStack(spacing: 4) {
                    TappableText("Terms of Service",
                                 url: AppConstants.Links.termsOfServiceURL,
                                 foregroundColor: .white)
                    Text("•")
                        .foregroundStyle(.white)
                        .font(.footnote)
                    TappableText("Privacy",
                                 url: AppConstants.Links.privacyPolicyURL,
                                 foregroundColor: .white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 48)
        .mainBackground()
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
