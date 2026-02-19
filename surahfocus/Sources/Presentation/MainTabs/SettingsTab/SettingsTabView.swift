import SwiftUI

struct SettingsTabView: View {
    @StateObject private var viewModel = SettingsTabViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 32) {
                // MARK: - Profile Section
                VStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(Color.secondary400)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(viewModel.displayInitial)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.black)
                        )

                    // Name
                    Text(viewModel.displayName)
                        .font(.system(.title2, weight: .semibold))
                        .foregroundColor(.white)

                    // Email
                    if let email = viewModel.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(Color.gray4)
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
            .padding(.top, 48)
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
