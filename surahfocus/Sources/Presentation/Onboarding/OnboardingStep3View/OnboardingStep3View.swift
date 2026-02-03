import SwiftUI

struct OnboardingStep3View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you want more of?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select what matters most")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(OnboardingSurvey.Goal.allCases, id: \.self) { goal in
                        SelectableCard(
                            text: goal.rawValue,
                            isSelected: viewModel.isGoalSelected(goal)
                        ) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
