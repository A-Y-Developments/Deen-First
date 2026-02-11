import SwiftUI

struct OnboardingStep3View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your heart craving for?")
                        .font(.system(.title, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Text("Bismillah, let's make it happen!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
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
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}
