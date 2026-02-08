import Foundation

// MARK: - DTOs for quranapi.pages.dev

struct SingleVerseResponse: Codable {
    let surahName: String
    let surahNameArabic: String
    let surahNameArabicLong: String
    let surahNameTranslation: String
    let revelationPlace: String
    let totalAyah: Int
    let surahNo: Int
    let ayahNo: Int
    let audio: [String: ReciterAudioDTO]
    let english: String
    let arabic1: String
    let arabic2: String

    enum CodingKeys: String, CodingKey {
        case surahName
        case surahNameArabic
        case surahNameArabicLong
        case surahNameTranslation
        case revelationPlace
        case totalAyah
        case surahNo
        case ayahNo
        case audio
        case english
        case arabic1
        case arabic2
    }
}

struct ReciterAudioDTO: Codable {
    let reciter: String
    let url: String
    let originalUrl: String

    enum CodingKeys: String, CodingKey {
        case reciter
        case url
        case originalUrl
    }
}

struct SurahListResponse: Codable {
    let surahs: [SurahMetadataDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dtos = try container.decode([SurahMetadataDTO].self)
        // Add surah numbers from array index (1-based)
        surahs = zip(1..., dtos).map { index, dto in
            SurahMetadataDTO(
                surahNo: index,
                surahName: dto.surahName,
                surahNameArabic: dto.surahNameArabic,
                surahNameArabicLong: dto.surahNameArabicLong,
                surahNameTranslation: dto.surahNameTranslation,
                revelationPlace: dto.revelationPlace,
                totalAyah: dto.totalAyah
            )
        }
    }
}

struct SurahMetadataDTO: Codable {
    let surahNo: Int
    let surahName: String
    let surahNameArabic: String
    let surahNameArabicLong: String
    let surahNameTranslation: String
    let revelationPlace: String
    let totalAyah: Int

    // For decoding from API (without surahNo)
    private enum CodingKeys: String, CodingKey {
        case surahName
        case surahNameArabic
        case surahNameArabicLong
        case surahNameTranslation
        case revelationPlace
        case totalAyah
    }

    // For manual initialization with surahNo
    init(
        surahNo: Int,
        surahName: String,
        surahNameArabic: String,
        surahNameArabicLong: String,
        surahNameTranslation: String,
        revelationPlace: String,
        totalAyah: Int
    ) {
        self.surahNo = surahNo
        self.surahName = surahName
        self.surahNameArabic = surahNameArabic
        self.surahNameArabicLong = surahNameArabicLong
        self.surahNameTranslation = surahNameTranslation
        self.revelationPlace = revelationPlace
        self.totalAyah = totalAyah
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.surahNo = 0 // Will be set by SurahListResponse
        self.surahName = try container.decode(String.self, forKey: .surahName)
        self.surahNameArabic = try container.decode(String.self, forKey: .surahNameArabic)
        self.surahNameArabicLong = try container.decode(String.self, forKey: .surahNameArabicLong)
        self.surahNameTranslation = try container.decode(String.self, forKey: .surahNameTranslation)
        self.revelationPlace = try container.decode(String.self, forKey: .revelationPlace)
        self.totalAyah = try container.decode(Int.self, forKey: .totalAyah)
    }
}

struct SurahChapterResponse: Codable {
    let surahName: String
    let surahNameArabic: String
    let surahNameArabicLong: String
    let surahNameTranslation: String
    let revelationPlace: String
    let totalAyah: Int
    let surahNo: Int
    let audio: [String: ReciterAudioDTO]
    let english: [String]
    let arabic1: [String]
    let arabic2: [String]

    func toVerses() -> [SingleVerseResponse] {
        guard english.count == arabic1.count && arabic1.count == arabic2.count else {
            return []
        }

        return zip(1..., english).map { index, englishText in
            SingleVerseResponse(
                surahName: surahName,
                surahNameArabic: surahNameArabic,
                surahNameArabicLong: surahNameArabicLong,
                surahNameTranslation: surahNameTranslation,
                revelationPlace: revelationPlace,
                totalAyah: totalAyah,
                surahNo: surahNo,
                ayahNo: index,
                audio: audio,
                english: englishText,
                arabic1: arabic1[index - 1],
                arabic2: arabic2[index - 1]
            )
        }
    }

    func toSurahEntity() -> Surah {
        Surah(
            number: surahNo,
            name: surahName,
            englishName: surahNameTranslation,
            englishNameTranslation: surahNameTranslation,
            numberOfAyahs: totalAyah,
            revelationPlace: revelationPlace,
            surahNameArabic: surahNameArabic,
            surahNameArabicLong: surahNameArabicLong
        )
    }
}

// MARK: - Entity Mappers

extension SingleVerseResponse {
    func toAyahEntity() -> Ayah {
        let audioUrlsArray = audio.compactMap { (key, value) -> ReciterAudio? in
            guard let reciterId = Int(key) else { return nil }
            return ReciterAudio(
                reciterId: reciterId,
                reciterName: value.reciter,
                url: value.url,
                originalUrl: value.originalUrl
            )
        }.sorted { $0.reciterId < $1.reciterId }

        return Ayah(
            number: ayahNo,
            text: arabic1,
            numberInSurah: ayahNo,
            english: english,
            arabic1: arabic1,
            arabic2: arabic2,
            audioUrls: audioUrlsArray,
            surahNo: surahNo,
            surahName: surahName
        )
    }
}

extension SingleVerseResponse {
    func toSurahEntity() -> Surah {
        Surah(
            number: surahNo,
            name: surahName,
            englishName: surahNameTranslation,
            englishNameTranslation: surahNameTranslation,
            numberOfAyahs: totalAyah,
            revelationPlace: revelationPlace,
            surahNameArabic: surahNameArabic,
            surahNameArabicLong: surahNameArabicLong
        )
    }
}

extension SurahMetadataDTO {
    func toSurahEntity() -> Surah {
        Surah(
            number: surahNo,
            name: surahName,
            englishName: surahNameTranslation,
            englishNameTranslation: surahNameTranslation,
            numberOfAyahs: totalAyah,
            revelationPlace: revelationPlace,
            surahNameArabic: surahNameArabic,
            surahNameArabicLong: surahNameArabicLong
        )
    }
}
