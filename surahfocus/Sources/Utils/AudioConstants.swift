import Foundation

enum AudioConstants {
    static let audioCacheDirectory = "AudioCache"
    static let fileExtension = "mp3"

    // UserDefaults keys
    static let lastSelectedSurahsKey = "lastSelectedSurahs"
    static let lastReciterIdKey = "lastReciterId"

    // Reciter IDs from quranaudio.pages.dev
    enum Reciter: Int, CaseIterable, Identifiable {
        case misharyAlafasy = 7
        case abdulBasit = 2
        case saadAlGhamdi = 5
        case abuBakrAlShatri = 3
        case haniArRifai = 1

        var id: Int { rawValue }
        var name: String {
            switch self {
            case .misharyAlafasy: return "Mishary Rashid Alafasy"
            case .abdulBasit: return "Abdul Basit Abdul Samad"
            case .saadAlGhamdi: return "Saad Al-Ghamdi"
            case .abuBakrAlShatri: return "Abu Bakr Al-Shatri"
            case .haniArRifai: return "Hani Ar-Rifai"
            }
        }

        static let `default` = Reciter.misharyAlafasy
    }
}
