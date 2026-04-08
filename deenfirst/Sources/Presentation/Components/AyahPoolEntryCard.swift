import SwiftUI

struct AyahPoolEntryCard: View {
    let count: Int
    let maxCount: Int
    let action: () -> Void

    private var badgeText: String {
        count == 0 ? "Empty" : "\(count)/\(maxCount) ayahs"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1A494D"))
                        .frame(width: 50, height: 50)
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("My Ayah Pool")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(badgeText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(Color.primary900)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
