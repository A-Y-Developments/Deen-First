import SwiftUI

struct EmptyActiveBlocksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Color(hex: "AEF29B"))

            Text("No active blocks")
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(.white)

            Text("Create blocks in Blocking tab to keep focus consistent.")
                .font(.system(.footnote))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
