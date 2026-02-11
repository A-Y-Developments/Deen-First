import SwiftUI

struct SessionFinishView: View {
    @EnvironmentObject var router: Router
    let duration: TimeInterval
    let surahCount: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 8) {
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Great job staying focused")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 16) {
                    StatRow(
                        icon: "clock.fill",
                        label: "Time Listened",
                        value: durationString
                    )

                    StatRow(
                        icon: "book.fill",
                        label: "Surahs Completed",
                        value: "\(surahCount)"
                    )

                    StatRow(
                        icon: "flame.fill",
                        label: "Streak",
                        value: "🔥 1"
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer()

                Button(action: navigateToHome) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding()
        }
        .navigationBarHidden(true)
    }

    private var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }

    private func navigateToHome() {
        router.navigateBack()
        router.navigateBack()
        router.navigateBack()
        router.navigateBack()
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        SessionFinishView(duration: 300, surahCount: 3)
    }
}
