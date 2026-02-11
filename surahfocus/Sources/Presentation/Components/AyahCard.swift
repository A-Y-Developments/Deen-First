import SwiftUI

struct AyahCard: View {
    let ayah: Ayah
    let showTranslation: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color(hex: "4facfe").opacity(0.1))
                        .frame(width: 32, height: 32)
                    Text("\(ayah.numberInSurah)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "4facfe"))
                }
            }

            Text(ayah.text)
                .font(.system(size: 24, weight: .medium))
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if showTranslation && !ayah.english.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .background(.white.opacity(0.2))
                        .padding(.vertical, 4)
                    Text(ayah.english)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
