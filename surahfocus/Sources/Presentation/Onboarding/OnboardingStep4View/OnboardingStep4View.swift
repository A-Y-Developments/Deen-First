import SwiftUI

struct OnboardingStep4View: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
//                    Text("Based on average usage:")
//                        .font(.system(size: 14))
//                        .foregroundColor(.white.opacity(0.7))
//
//                    Text("You spend ~2.5 hours\ndaily on social media")
//                        .font(.system(size: 32, weight: .bold))
//                        .foregroundColor(.white)
//                        .multilineTextAlignment(.center)
                    Text("MashaAllah...")
                        .font(.system(.title, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text("2.5")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(Color(hex: "ADA666"))
                        Text("hours")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "ADA666"))
                            .italic()
                    }
                    Text("on social media?")
                        .font(.system(.title, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Text("Yalla! that's actually enough time to get:")
                        .foregroundStyle(Color(hex: "8E8E93"))
                        .font(.system(.subheadline))
                    
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 20) {

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
