import SwiftUI

struct ScreenTimePermissionView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: ScreenTimePermissionViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("Screen Time Permission")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("To block distracting apps, we need Screen Time permission. This allows Surah Focus to temporarily restrict apps during your Quran sessions.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "checkmark.circle.fill", text: "Permission is required to use app blocking")
                    InfoRow(icon: "checkmark.circle.fill", text: "You control what gets blocked")
                    InfoRow(icon: "checkmark.circle.fill", text: "We never access your personal data")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        Task {
                            await viewModel.requestAuthorization()
                            if viewModel.isAuthorized {
                                router.navigate(to: .appSelection)
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Grant Permission")
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

                    Button("I'll do this later") {
                        viewModel.skip()
                        router.replaceWith(.mainTabs)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.checkAuthorization()
            if viewModel.isAuthorized {
                router.replaceWith(.appSelection)
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4facfe"))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

#Preview {
    ScreenTimePermissionView()
        .environmentObject(Router())
        .environmentObject(ScreenTimePermissionViewModel())
}
