import Foundation

struct Surah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationPlace: String
    let surahNameArabic: String
    let surahNameArabicLong: String

    init(
        number: Int,
        name: String,
        englishName: String,
        englishNameTranslation: String,
        numberOfAyahs: Int,
        revelationPlace: String,
        surahNameArabic: String = "",
        surahNameArabicLong: String = ""
    ) {
        self.id = number
        self.number = number
        self.name = name
        self.englishName = englishName
        self.englishNameTranslation = englishNameTranslation
        self.numberOfAyahs = numberOfAyahs
        self.revelationPlace = revelationPlace
        self.surahNameArabic = surahNameArabic
        self.surahNameArabicLong = surahNameArabicLong
    }
}
