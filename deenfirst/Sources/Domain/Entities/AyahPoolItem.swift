import Foundation
import SwiftData

@Model final class AyahPoolItem {
    @Attribute(.unique) var id: UUID
    var surahNumber: Int
    var ayahNumberInSurah: Int
    var arabicText: String
    var transliteration: String
    var wordCount: Int
    var addedAt: Date

    init(
        surahNumber: Int,
        ayahNumberInSurah: Int,
        arabicText: String,
        transliteration: String,
        wordCount: Int
    ) {
        self.id = UUID()
        self.surahNumber = surahNumber
        self.ayahNumberInSurah = ayahNumberInSurah
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.wordCount = wordCount
        self.addedAt = Date()
    }
}
