import Foundation

struct AyahAudio: Identifiable, Hashable {
    let id: String // "{reciterId}_{surahNo}_{ayahNo}"
    let reciterId: Int
    let surahNumber: Int
    let ayahNumber: Int
    var localURL: URL?
    var isCached: Bool { localURL != nil }
    var downloadURL: URL

    init(reciterId: Int, surahNumber: Int, ayahNumber: Int) {
        self.id = "\(reciterId)_\(surahNumber)_\(ayahNumber)"
        self.reciterId = reciterId
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        // quranaudio.pages.dev/{reciterNo}/{surahNo}_{ayahNo}.mp3
        self.downloadURL = URL(string: "https://quranaudio.pages.dev/\(reciterId)/\(surahNumber)_\(ayahNumber).mp3")!
    }
}

struct AyahAudioDownloadProgress: Identifiable {
    let id = UUID()
    let ayahAudio: AyahAudio
    var progress: Double // 0.0 to 1.0
    var isComplete: Bool { progress >= 1.0 }
    var error: Error?
}
