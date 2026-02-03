//
//  blocked_app.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

@Model
class BlockedApp {
    var id: String
    var bundleId: String
    var name: String
    var timeLimit: TimeInterval

    init(
        id: String = UUID().uuidString,
        bundleId: String,
        name: String,
        timeLimit: TimeInterval = 0
    ) {
        self.id = id
        self.bundleId = bundleId
        self.name = name
        self.timeLimit = timeLimit
    }
}
