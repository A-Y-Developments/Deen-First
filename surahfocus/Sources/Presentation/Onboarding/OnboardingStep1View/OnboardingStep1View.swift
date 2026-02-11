import SwiftUI

struct OnboardingStep1View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 8) {
                    Text("What brings you here today?")
                        .font(.system(.title, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
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
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}
