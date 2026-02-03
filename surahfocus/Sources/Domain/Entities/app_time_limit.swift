//
//  app_time_limit.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

@Model
class AppTimeLimit {
    var id: String
    var bundleId: String
    var dailyMinutes: Int

    init(
        id: String = UUID().uuidString,
        bundleId: String,
        dailyMinutes: Int
    ) {
        self.id = id
        self.bundleId = bundleId
        self.dailyMinutes = dailyMinutes
    }
}
