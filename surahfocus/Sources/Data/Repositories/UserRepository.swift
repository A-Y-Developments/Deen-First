//
//  UserRepository.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation

protocol UserRepository {
    func getUser() async throws -> User?
    func createUser(_ user: User) async throws
    func updateUser(_ apply: @escaping (User) -> Void) async throws
}

class UserRepositoryImpl: UserRepository {
    private let localDataSource: LocalDataSource

    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func getUser() async throws -> User? {
        return try localDataSource.getUser()
    }

    func createUser(_ user: User) async throws {
        try localDataSource.saveUser(user)
    }

    func updateUser(_ apply: @escaping (User) -> Void) async throws {
        try localDataSource.updateUser(apply)
    }
}
