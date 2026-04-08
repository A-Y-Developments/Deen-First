import Foundation

// MARK: - Protocol

protocol AyahPoolService {
    func fetchPool() async throws -> [AyahPoolItem]
}

// MARK: - Implementation

final class AyahPoolServiceImpl: AyahPoolService {
    private let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func fetchPool() async throws -> [AyahPoolItem] {
        try await localDataSource.fetchAyahPool()
    }
}
