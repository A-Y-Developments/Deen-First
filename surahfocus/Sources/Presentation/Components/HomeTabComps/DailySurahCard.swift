import SwiftUI

struct DailySurahCard: View {
    let surah: Surah
    let action: () -> Void

    private var arabicName: String {
        surah.surahNameArabic.isEmpty ? surah.name : surah.surahNameArabic
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Daily")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.primary900)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "AEF29B"))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A494D"))
                            .frame(width: 48, height: 48)

                        Text("\(surah.number)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(arabicName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text(surah.englishNameTranslation)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
