//
//  DIContainer.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

final class DIContainer {
    private let modelContainer: ModelContainer

    static let shared: DIContainer = {
        do {
            let container = try ModelContainer(for: User.self)
            return DIContainer(modelContainer: container)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    lazy var localDataSource: LocalDataSource = LocalDataSource(container: modelContainer)

    lazy var userRepository: UserRepository = UserRepositoryImpl(localDataSource: localDataSource)
}
