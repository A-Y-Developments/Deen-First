import SwiftUI

struct OnboardingStep4View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Based on average usage:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    Text("You spend ~2.5 hours\ndaily on social media")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 20) {
                    Text("That's enough time to:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    TimeComparisonRow(icon: "📖", text: "Read 5 surahs of the Quran")
                    TimeComparisonRow(icon: "⏰", text: "Complete 30 minutes of focused work")
                    TimeComparisonRow(icon: "💬", text: "Have meaningful conversations")
                }
                .padding(.horizontal, 24)

                Text("Let's create space for what matters 🌙")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}

struct TimeComparisonRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 32))

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
