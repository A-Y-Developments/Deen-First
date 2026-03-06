import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var viewModel: SettingsTabViewModel
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
                    Button { router.navigate(to: .emergencyUnblock) } label: {
                        SettingsRow(title: "Emergency Unblock")
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Footer
                VStack(spacing: 16) {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        SettingsRow(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right")
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        TappableText("Terms of Service",
                                     url: AppConstants.Links.termsOfServiceURL,
                                     foregroundColor: Color(hex: "#8E8E93"))
                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#8E8E93"))
                        TappableText("Privacy",
                                     url: AppConstants.Links.privacyPolicyURL,
                                     foregroundColor: Color(hex: "#8E8E93"))
                    }
                }
                .padding(.top, 16)

                Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 48)
        .mainBackground()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
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
