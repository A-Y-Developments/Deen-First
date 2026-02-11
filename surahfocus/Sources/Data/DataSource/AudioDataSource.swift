import Foundation

protocol AudioDataSource {
    func downloadAudio(from url: URL, to destinationURL: URL) async throws -> DownloadProgress
    func checkCache(for audio: AyahAudio) -> URL?
}

struct DownloadProgress {
    var bytesReceived: Int64
    var totalBytes: Int64
    var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesReceived) / Double(totalBytes)
    }
}

final class AudioDataSourceImpl: AudioDataSource {
    private let session: URLSession
    private let fileManager = FileManager.default
    private let fileHelper = AudioFileHelper.shared

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
    }

    func downloadAudio(from url: URL, to destinationURL: URL) async throws -> DownloadProgress {
        let parentDir = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try? fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var progress = DownloadProgress(bytesReceived: 0, totalBytes: 0)

        do {
            let (data, response) = try await session.data(from: url)
            progress.totalBytes = response.expectedContentLength
            progress.bytesReceived = Int64(data.count)

            try data.write(to: destinationURL)
        } catch {
            throw error
        }

        return progress
    }

    func checkCache(for audio: AyahAudio) -> URL? {
        let url = fileHelper.fileURL(for: audio)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
