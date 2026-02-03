//
//  LocalDataSource.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

final class LocalDataSource {
    let container: ModelContainer
    let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func getUser() throws -> User? {
        let descriptor = FetchDescriptor<User>()
        var users = try context.fetch(descriptor)
        return users.first
    }

    func saveUser(_ user: User) throws {
        context.insert(user)
        try context.save()
    }

    func updateUser(_ apply: (User) -> Void) throws {
        guard let user = try getUser() else {
            throw LocalDataSourceError.userNotFound
        }
        apply(user)
        try context.save()
    }
}

enum LocalDataSourceError: Error {
    case userNotFound
}
