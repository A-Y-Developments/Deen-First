import SwiftUI

struct ReciteAlertView: View {
    let appName: String
    let onRecite: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#1A4731"), Color(hex: "#2D7A50")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 28)

            Text("Read Quran First")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 12)

            Text("Take a moment to read one ayah because\nyou've reached your limit on \(appName).")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onRecite) {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Recite Ayah")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(hex: "#1A4731"))
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            Button(action: onLater) {
                Text("Maybe Later")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(height: 44)
            }
            .padding(.bottom, 24)
        }
        .background(Color.primary900)
    }
}

// MARK: - Preview
#Preview {
    ReciteAlertView(
        appName: "Instagram",
        onRecite: {},
        onLater: {}
    )
}
