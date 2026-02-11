import Foundation

final class AudioFileHelper {
    static let shared = AudioFileHelper()

    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent(AudioConstants.audioCacheDirectory)

        // Create directory if doesn't exist
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        return cacheDir
    }()

    private init() {}

    func fileURL(for audio: AyahAudio) -> URL {
        return cacheDirectory.appendingPathComponent("\(audio.id).\(AudioConstants.fileExtension)")
    }

    func isCached(_ audio: AyahAudio) -> Bool {
        let url = fileURL(for: audio)
        return fileManager.fileExists(atPath: url.path)
    }

    func removeFile(for audio: AyahAudio) throws {
        let url = fileURL(for: audio)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func clearAllCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }

    func cacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        let totalSize = contents.compactMap { (url: URL) -> Int? in
            guard let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                return nil
            }
            return fileSize
        }.reduce(0, +)
        return Int64(totalSize)
    }
}
