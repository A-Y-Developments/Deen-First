import Foundation

// MARK: - DTOs for api.alquran.cloud (transliteration)

struct AlQuranSurahResponse: Codable {
    let code: Int
    let data: AlQuranSurahData
}

struct AlQuranSurahData: Codable {
    let ayahs: [AlQuranAyahDTO]
}

struct AlQuranAyahDTO: Codable {
    let numberInSurah: Int
    let text: String
}

struct AlQuranVerseResponse: Codable {
    let code: Int
    let data: AlQuranAyahDTO
}
