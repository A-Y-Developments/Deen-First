import Foundation
import SwiftData

protocol AppLimitRepository {
    func create(_ limit: AppLimit) async throws
    func getAll() async throws -> [AppLimit]
    func get(id: UUID) async throws -> AppLimit?
    func update(_ limit: AppLimit) async throws
    func delete(_ limit: AppLimit) async throws
}

final class AppLimitRepositoryImpl: AppLimitRepository {
    let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func create(_ limit: AppLimit) async throws {
        try await MainActor.run {
            try localDataSource.insertAppLimit(limit)
        }
    }

    func getAll() async throws -> [AppLimit] {
        try await MainActor.run {
            try localDataSource.getAllAppLimits()
        }
    }

    func get(id: UUID) async throws -> AppLimit? {
        try await MainActor.run {
            try localDataSource.getAppLimit(id: id)
        }
    }

    func update(_ limit: AppLimit) async throws {
        try await MainActor.run {
            try localDataSource.updateAppLimit(limit)
        }
    }

    func delete(_ limit: AppLimit) async throws {
        try await MainActor.run {
            try localDataSource.deleteAppLimit(limit)
        }
    }
}
