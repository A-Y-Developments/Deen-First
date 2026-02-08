import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "4facfe"))
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("Phase 7: Profile, subscription, and app settings")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top, endPoint: .bottom
            )
        )
        .navigationTitle("Settings")
    }
}
