import Foundation

struct Ayah: Identifiable, Codable, Hashable {
    let id: Int
    let number: Int
    let text: String
    let numberInSurah: Int
    let translation: String?

    init(number: Int, text: String, numberInSurah: Int, translation: String? = nil) {
        self.id = number
        self.number = number
        self.text = text
        self.numberInSurah = numberInSurah
        self.translation = translation
    }
}
