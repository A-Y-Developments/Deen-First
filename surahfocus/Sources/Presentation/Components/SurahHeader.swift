import SwiftUI

struct SurahHeader: View {
    let surah: Surah

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(surah.surahNameArabicLong)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text(surah.englishNameTranslation)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
            HStack(spacing: 16) {
                Label("\(surah.numberOfAyahs) Ayahs", systemImage: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                Text("·")
                    .foregroundColor(.white.opacity(0.7))
                Text(surah.revelationPlace)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "4facfe").opacity(0.1),
                    Color(hex: "00f2fe").opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}
