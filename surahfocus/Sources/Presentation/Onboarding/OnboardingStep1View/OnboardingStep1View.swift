import SwiftUI

struct OnboardingStep1View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What brings you here today?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select all that apply")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(OnboardingSurvey.Motivation.allCases, id: \.self) { motivation in
                        SelectableCard(
                            text: motivation.rawValue,
                            isSelected: viewModel.isMotivationSelected(motivation)
                        ) {
                            viewModel.toggleMotivation(motivation)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
