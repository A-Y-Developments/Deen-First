import Foundation

enum TranslationLanguage: String, CaseIterable, Codable {
    case english
    case bengali
    case urdu

    var displayName: String {
        switch self {
        case .english: return "English"
        case .bengali: return "Bengali"
        case .urdu: return "Urdu"
        }
    }
}
