import SwiftUI
import ManagedSettings
import FamilyControls

struct AppLimitSetupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: AppLimitSetupViewModel

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

                VStack(spacing: 16) {
                    Text("Daily time limit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("How much time can you spend on these apps per day?")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                if !viewModel.selectedApps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(viewModel.selectedApps.count) apps selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.selectedApps.prefix(5)), id: \.self) { _ in
                                Image(systemName: "app.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "4facfe"))
                            }

                            if viewModel.selectedApps.count > 5 {
                                Text("+\(viewModel.selectedApps.count - 5)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    ForEach(TimeLimit.allCases, id: \.self) { limit in
                        TimeLimitCard(
                            limit: limit,
                            isSelected: viewModel.selectedLimit == limit
                        ) {
                            viewModel.setLimit(limit)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        viewModel.save()
                        passAppsToNextScreen()
                        Task {
                            await markAppLimitSetupComplete()
                            router.navigate(to: .downtimeSetup)
                        }
                    } label: {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }

                    Button("Skip") {
                        viewModel.skip()
                        passAppsToNextScreen()
                        Task {
                            await markAppLimitSetupComplete()
                            router.navigate(to: .downtimeSetup)
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            loadSelectedApps()
        }
    }

    private func loadSelectedApps() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let appDataArray = sharedDefaults.array(forKey: "selectedAppsForSetup") as? [Data] else {
            router.navigateBack()
            return
        }

        let tokens = appDataArray.compactMap { data -> ApplicationToken? in
            try? JSONDecoder().decode(ApplicationToken.self, from: data)
        }

        viewModel.loadApps(tokens)
    }

    private func passAppsToNextScreen() {}

    @MainActor
    private func markAppLimitSetupComplete() async {
        if let user = try? await DIContainer.shared.authService.getCurrentUser() {
            user.hasCompletedAppLimitSetup = true
            try? await DIContainer.shared.userRepository.updateUser(user)
        }
    }
}

struct TimeLimitCard: View {
    let limit: TimeLimit
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(limit.displayName)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "4facfe"))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    AppLimitSetupView()
        .environmentObject(Router())
        .environmentObject(AppLimitSetupViewModel())
}
