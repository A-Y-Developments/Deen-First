import SwiftUI

struct SurahCard: View {
    let surah: Surah
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1A494D"))
                        .frame(width: 50, height: 50)
                    Text("\(surah.number)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(surah.englishName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(surah.englishNameTranslation)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
