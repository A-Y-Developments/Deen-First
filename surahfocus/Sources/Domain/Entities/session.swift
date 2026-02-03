//
//  session.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import Foundation
import SwiftData

@Model
class Session {
    var id: String
    var date: Date
    var duration: TimeInterval
    var surahs: [String]

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        duration: TimeInterval = 0,
        surahs: [String] = []
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.surahs = surahs
    }
}
