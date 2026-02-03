import SwiftUI

struct OnboardingStep2View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When does your phone distract you most?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select all that apply")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    SelectableCard(
                        text: "Late at night",
                        icon: "🌙",
                        isSelected: viewModel.isDistractionTimeSelected(.lateNight)
                    ) {
                        viewModel.toggleDistractionTime(.lateNight)
                    }

                    SelectableCard(
                        text: "When I feel overwhelmed",
                        icon: "😰",
                        isSelected: viewModel.isDistractionTimeSelected(.overwhelmed)
                    ) {
                        viewModel.toggleDistractionTime(.overwhelmed)
                    }

                    SelectableCard(
                        text: "Throughout the day",
                        icon: "☀️",
                        isSelected: viewModel.isDistractionTimeSelected(.throughout)
                    ) {
                        viewModel.toggleDistractionTime(.throughout)
                    }

                    SelectableCard(
                        text: "When I feel stressed",
                        icon: "😓",
                        isSelected: viewModel.isDistractionTimeSelected(.stressed)
                    ) {
                        viewModel.toggleDistractionTime(.stressed)
                    }

                    SelectableCard(
                        text: "For a minute (turns into hours)",
                        icon: "⏱️",
                        isSelected: viewModel.isDistractionTimeSelected(.quickCheck)
                    ) {
                        viewModel.toggleDistractionTime(.quickCheck)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
