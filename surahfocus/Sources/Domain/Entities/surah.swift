import Foundation

struct Surah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String

    init(number: Int, name: String, englishName: String, englishNameTranslation: String, numberOfAyahs: Int, revelationType: String) {
        self.id = number
        self.number = number
        self.name = name
        self.englishName = englishName
        self.englishNameTranslation = englishNameTranslation
        self.numberOfAyahs = numberOfAyahs
        self.revelationType = revelationType
    }
}
