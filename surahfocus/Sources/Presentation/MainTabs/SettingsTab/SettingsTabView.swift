import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var viewModel: SettingsTabViewModel
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @EnvironmentObject var router: Router

    var body: some View {
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
                    Button { router.navigate(to: .subscription) } label: {
                        SettingsRow(title: "Subscription")
                    }
                    .buttonStyle(.plain)
                    Button { router.navigate(to: .preferences) } label: {
                        SettingsRow(title: "Preferences")
                    }
                    .buttonStyle(.plain)
                    Button { router.navigate(to: .support) } label: {
                        SettingsRow(title: "Help & Support")
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Footer
                VStack(spacing: 16) {
                    Button {
                        showSignOutConfirmation = true
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
        .background {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
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
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            await viewModel.loadUserData()
        }
    }
}
