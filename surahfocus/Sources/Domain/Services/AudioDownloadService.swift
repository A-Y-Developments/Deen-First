import Foundation
import Combine

protocol AudioDownloadService: ObservableObject {
    var isDownloading: Bool { get set }
    var overallProgress: Double { get set }
    var downloadedCount: Int { get set }
    var totalCount: Int { get set }
    var downloadQueue: [AyahAudioDownloadProgress] { get set }

    func downloadAyahs(_ ayahAudios: [AyahAudio]) async throws
    func cancelDownloads()
    func clearCache() throws
}

@MainActor
final class AudioDownloadServiceImpl: AudioDownloadService {
    @Published var isDownloading: Bool = false
    @Published var overallProgress: Double = 0
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var downloadQueue: [AyahAudioDownloadProgress] = []

    private let audioDataSource: AudioDataSource
    private var downloadTasks: Task<Void, Never>?

    init(audioDataSource: AudioDataSource = AudioDataSourceImpl()) {
        self.audioDataSource = audioDataSource
    }

    func downloadAyahs(_ ayahAudios: [AyahAudio]) async throws {
        guard !isDownloading else { return }

        isDownloading = true
        downloadedCount = 0
        totalCount = ayahAudios.count
        overallProgress = 0

        downloadQueue = ayahAudios.map { ayahAudio in
            AyahAudioDownloadProgress(ayahAudio: ayahAudio, progress: 0)
        }

        downloadTasks = Task {
            await downloadAll(ayahAudios)
        }

        try await downloadTasks?.value

        downloadTasks = nil
        isDownloading = false
    }

    private func downloadAll(_ ayahAudios: [AyahAudio]) async {
        for (index, ayahAudio) in ayahAudios.enumerated() {
            guard !Task.isCancelled else { break }

            await downloadSingle(ayahAudio, index: index)

            downloadedCount += 1
            overallProgress = Double(downloadedCount) / Double(totalCount)
        }
    }

    private func downloadSingle(_ ayahAudio: AyahAudio, index: Int) async {
        let fileURL = AudioFileHelper.shared.fileURL(for: ayahAudio)

        if audioDataSource.checkCache(for: ayahAudio) != nil {
            updateProgress(for: index, progress: 1.0)
            return
        }

        do {
            let _ = try await audioDataSource.downloadAudio(
                from: ayahAudio.downloadURL,
                to: fileURL
            )

            updateProgress(for: index, progress: 1.0)
        } catch {
            updateProgress(for: index, error: error)
        }
    }

    private func updateProgress(for index: Int, progress: Double) {
        guard index < downloadQueue.count else { return }
        downloadQueue[index].progress = progress
    }

    private func updateProgress(for index: Int, error: Error) {
        guard index < downloadQueue.count else { return }
        downloadQueue[index].error = error
        downloadQueue[index].progress = 0
    }

    func cancelDownloads() {
        downloadTasks?.cancel()
        downloadTasks = nil
        isDownloading = false
        downloadQueue.removeAll()
    }

    func clearCache() throws {
        try AudioFileHelper.shared.clearAllCache()
    }
}
