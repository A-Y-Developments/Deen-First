import Foundation

struct Ayah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let text: String
    let numberInSurah: Int
    let english: String
    let arabic1: String
    let arabic2: String
    let audioUrls: [ReciterAudio]
    let surahNo: Int
    let surahName: String

    init(
        number: Int,
        text: String,
        numberInSurah: Int,
        english: String = "",
        arabic1: String = "",
        arabic2: String = "",
        audioUrls: [ReciterAudio] = [],
        surahNo: Int = 0,
        surahName: String = ""
    ) {
        self.id = number
        self.number = number
        self.text = text
        self.numberInSurah = numberInSurah
        self.english = english
        self.arabic1 = arabic1
        self.arabic2 = arabic2
        self.audioUrls = audioUrls
        self.surahNo = surahNo
        self.surahName = surahName
    }
}
