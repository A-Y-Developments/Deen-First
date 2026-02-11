import Foundation

struct SurahWithRange: Identifiable {
    var id: Int { surah.number }
    let surah: Surah
    var startAyah: Int
    var endAyah: Int
    var totalAyahs: Int { surah.numberOfAyahs }

    var ayahRange: ClosedRange<Int> {
        min(startAyah, endAyah)...max(startAyah, endAyah)
    }

    var ayahCount: Int {
        ayahRange.count
    }

    var isValid: Bool {
        startAyah >= 1 && endAyah <= totalAyahs && startAyah <= endAyah
    }

    func ayahNumbers() -> [Int] {
        Array(ayahRange)
    }
}

extension SurahWithRange: Hashable {
    static func == (lhs: SurahWithRange, rhs: SurahWithRange) -> Bool {
        lhs.surah.number == rhs.surah.number &&
        lhs.startAyah == rhs.startAyah &&
        lhs.endAyah == rhs.endAyah
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(surah.number)
        hasher.combine(startAyah)
        hasher.combine(endAyah)
    }
}
