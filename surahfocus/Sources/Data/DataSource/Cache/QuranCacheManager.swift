import Foundation

actor QuranCacheManager {
    private let cacheDirectory: URL
    private let cacheExpiration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    private let fileManager = FileManager.default

    private struct CacheMetadata: Codable {
        let timestamp: Date
        let appVersion: String
    }

    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("QuranCache", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        Task {
            await clearCacheIfNeeded()
        }
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func cacheFileURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key).plist")
    }

    private func metadataFileURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key)_metadata.plist")
    }

    private func isCacheValid(for key: String) -> Bool {
        let metadataURL = metadataFileURL(for: key)

        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? PropertyListDecoder().decode(CacheMetadata.self, from: data) else {
            return false
        }

        let versionMatch = metadata.appVersion == currentAppVersion
        let expirationCheck = Date().timeIntervalSince(metadata.timestamp) < cacheExpiration

        return versionMatch && expirationCheck
    }

    private func clearCacheIfNeeded() {
        let metadataURL = metadataFileURL(for: "app_version")
        if fileManager.fileExists(atPath: metadataURL.path),
           let data = try? Data(contentsOf: metadataURL),
           let metadata = try? PropertyListDecoder().decode(CacheMetadata.self, from: data),
           metadata.appVersion != currentAppVersion {
            clearCache()
        }

        let newMetadata = CacheMetadata(timestamp: Date(), appVersion: currentAppVersion)
        if let data = try? PropertyListEncoder().encode(newMetadata) {
            try? data.write(to: metadataURL)
        }
    }

    func cacheSurahList(_ surahs: [Surah]) {
        let fileURL = cacheFileURL(for: "surah_list")
        let metadataURL = metadataFileURL(for: "surah_list")

        guard let data = try? PropertyListEncoder().encode(surahs) else { return }
        try? data.write(to: fileURL)

        let metadata = CacheMetadata(timestamp: Date(), appVersion: currentAppVersion)
        if let metadataData = try? PropertyListEncoder().encode(metadata) {
            try? metadataData.write(to: metadataURL)
        }
    }

    func getCachedSurahList() -> [Surah]? {
        guard isCacheValid(for: "surah_list") else { return nil }

        let fileURL = cacheFileURL(for: "surah_list")
        guard let data = try? Data(contentsOf: fileURL),
              let surahs = try? PropertyListDecoder().decode([Surah].self, from: data) else {
            return nil
        }

        return surahs
    }

    func cacheSurah(number: Int, surah: Surah, ayahs: [Ayah]) {
        struct SurahData: Codable {
            let surah: Surah
            let ayahs: [Ayah]
        }

        let key = "surah_\(number)"
        let fileURL = cacheFileURL(for: key)
        let metadataURL = metadataFileURL(for: key)

        let surahData = SurahData(surah: surah, ayahs: ayahs)
        guard let data = try? PropertyListEncoder().encode(surahData) else { return }
        try? data.write(to: fileURL)

        let metadata = CacheMetadata(timestamp: Date(), appVersion: currentAppVersion)
        if let metadataData = try? PropertyListEncoder().encode(metadata) {
            try? metadataData.write(to: metadataURL)
        }
    }

    func getCachedSurah(number: Int) -> (Surah, [Ayah])? {
        let key = "surah_\(number)"
        guard isCacheValid(for: key) else { return nil }

        struct SurahData: Codable {
            let surah: Surah
            let ayahs: [Ayah]
        }

        let fileURL = cacheFileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let surahData = try? PropertyListDecoder().decode(SurahData.self, from: data) else {
            return nil
        }

        return (surahData.surah, surahData.ayahs)
    }

    func cacheVerse(surahNo: Int, ayahNo: Int, verse: Ayah) {
        let key = "verse_\(surahNo)_\(ayahNo)"
        let fileURL = cacheFileURL(for: key)
        let metadataURL = metadataFileURL(for: key)

        guard let data = try? PropertyListEncoder().encode(verse) else { return }
        try? data.write(to: fileURL)

        let metadata = CacheMetadata(timestamp: Date(), appVersion: currentAppVersion)
        if let metadataData = try? PropertyListEncoder().encode(metadata) {
            try? metadataData.write(to: metadataURL)
        }
    }

    func getCachedVerse(surahNo: Int, ayahNo: Int) -> Ayah? {
        let key = "verse_\(surahNo)_\(ayahNo)"
        guard isCacheValid(for: key) else { return nil }

        let fileURL = cacheFileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let verse = try? PropertyListDecoder().decode(Ayah.self, from: data) else {
            return nil
        }

        return verse
    }

    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func clearExpiredCache() {
        var keys = ["surah_list", "app_version"]

        for i in 1...114 {
            keys.append("surah_\(i)")
        }

        for key in keys {
            let metadataURL = metadataFileURL(for: key)
            if fileManager.fileExists(atPath: metadataURL.path),
               let data = try? Data(contentsOf: metadataURL),
               let metadata = try? PropertyListDecoder().decode(CacheMetadata.self, from: data) {
                if Date().timeIntervalSince(metadata.timestamp) >= cacheExpiration {
                    let fileURL = cacheFileURL(for: key)
                    try? fileManager.removeItem(at: fileURL)
                    try? fileManager.removeItem(at: metadataURL)
                }
            }
        }
    }
}
