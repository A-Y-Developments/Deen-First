import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: OnboardingScreenTimeViewModel

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
                VStack(spacing: 16) {
                    Text("Let's start simple")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Which app distracts you most?")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))

                    Text("You can select more apps or edit this later")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)

                Button {
                    viewModel.openPicker()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "4facfe"))

                        Text(selectionText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    router.navigate(to: .appLimitSetup)
                } label: {
                    HStack {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        (viewModel.selectedAppsCount > 0 || viewModel.selectedCategoriesCount > 0) ?
                        LinearGradient(
                            colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(viewModel.selectedAppsCount == 0 && viewModel.selectedCategoriesCount == 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Error message display
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.selection
        )
        .onChange(of: viewModel.selection) { oldValue, newValue in
            viewModel.updateSelection(newValue)
        }
        .navigationBarBackButtonHidden()
    }

    private var selectionText: String {
        let apps = viewModel.selectedAppsCount
        let categories = viewModel.selectedCategoriesCount

        if apps == 0 && categories == 0 {
            return "Select Apps"
        } else if apps > 0 && categories > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s"), \(categories) categor\(categories == 1 ? "y" : "ies")"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s") selected"
        } else {
            return "\(categories) categor\(categories == 1 ? "y" : "ies") selected"
        }
    }
}

#Preview {
    AppSelectionView()
        .environmentObject(Router())
        .environmentObject(OnboardingScreenTimeViewModel())
}
