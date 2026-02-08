import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 24))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak) day streak")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Keep it going!")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "FFE5B4").opacity(0.3),
                    Color(hex: "FFD700").opacity(0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}
