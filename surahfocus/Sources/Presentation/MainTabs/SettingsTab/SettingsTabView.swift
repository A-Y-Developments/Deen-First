import SwiftUI

struct SettingsTabView: View {
    @StateObject private var viewModel = SettingsTabViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // MARK: - Profile Section
                VStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(Color(hex: "#ADA666"))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(viewModel.displayInitial)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    // Name
                    Text(viewModel.displayName)
                        .font(.system(.title2, weight: .semibold))
                        .foregroundColor(.white)

                    // Email
                    if let email = viewModel.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#8E8E93"))
                    }
                }
                .padding(.top, 40)

                // MARK: - Menu Section
                VStack(spacing: 16) {
                    SettingsRow(title: "Subscription")
                    SettingsRow(title: "Preferences")
                    SettingsRow(title: "Help & Support")
                }

                // MARK: - Footer
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await viewModel.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .underline()
                    }

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Account")
                            .font(.caption)
                            .foregroundColor(.red)
                            .underline()
                    }

                    Text("Terms of Service • Privacy")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .padding(.top, 16)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .task {
            await viewModel.loadUserData()
        }
    }
}
