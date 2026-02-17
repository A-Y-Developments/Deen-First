import Foundation
import SwiftData

protocol TimeLimitRepository {
    func create(_ limit: TimeLimitSettings) async throws
    func getAll(for userId: UUID) async throws -> [TimeLimitSettings]
    func get(id: UUID) async throws -> TimeLimitSettings?
    func update(_ limit: TimeLimitSettings) async throws
    func delete(_ limit: TimeLimitSettings) async throws
}

final class TimeLimitRepositoryImpl: TimeLimitRepository {
    let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func create(_ limit: TimeLimitSettings) async throws {
        try await MainActor.run {
            try localDataSource.insertTimeLimit(limit)
        }
    }

    func getAll(for userId: UUID) async throws -> [TimeLimitSettings] {
        try await MainActor.run {
            try localDataSource.getAllTimeLimits(for: userId)
        }
    }

    func get(id: UUID) async throws -> TimeLimitSettings? {
        try await MainActor.run {
            try localDataSource.getTimeLimit(id: id)
        }
    }

    func update(_ limit: TimeLimitSettings) async throws {
        try await MainActor.run {
            try localDataSource.updateTimeLimit(limit)
        }
    }

    func delete(_ limit: TimeLimitSettings) async throws {
        try await MainActor.run {
            try localDataSource.deleteTimeLimit(limit)
        }
    }
}
