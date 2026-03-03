import Foundation

struct Ayah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let text: String
    let numberInSurah: Int
    let english: String
    let bengali: String
    let urdu: String
    let arabic1: String
    let arabic2: String
    let audioUrls: [ReciterAudio]
    let surahNo: Int
    let surahName: String
    let transliteration: String

    // Convenience property to get translation by language
    func translation(for language: TranslationLanguage) -> String {
        switch language {
        case .english: return english
        case .bengali: return bengali
        case .urdu: return urdu
        }
    }

    init(
        number: Int,
        text: String,
        numberInSurah: Int,
        english: String = "",
        bengali: String = "",
        urdu: String = "",
        arabic1: String = "",
        arabic2: String = "",
        audioUrls: [ReciterAudio] = [],
        surahNo: Int = 0,
        surahName: String = "",
        transliteration: String = ""
    ) {
        self.id = number
        self.number = number
        self.text = text
        self.numberInSurah = numberInSurah
        self.english = english
        self.bengali = bengali
        self.urdu = urdu
        self.arabic1 = arabic1
        self.arabic2 = arabic2
        self.audioUrls = audioUrls
        self.surahNo = surahNo
        self.surahName = surahName
        self.transliteration = transliteration
    }

    func withTransliteration(_ t: String) -> Ayah {
        Ayah(
            number: number,
            text: text,
            numberInSurah: numberInSurah,
            english: english,
            bengali: bengali,
            urdu: urdu,
            arabic1: arabic1,
            arabic2: arabic2,
            audioUrls: audioUrls,
            surahNo: surahNo,
            surahName: surahName,
            transliteration: t
        )
    }
}
