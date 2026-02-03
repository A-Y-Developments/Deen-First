import SwiftUI

struct AppLogo: View {
    let size: CGFloat

    init(size: CGFloat = 80) {
        self.size = size
    }

    var body: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
