//
//  PrayerTime.swift
//  SurahFocus
//

import Foundation

enum PrayerTime: String, CaseIterable {
    case subuh   = "subuh"
    case zuhr    = "zuhr"
    case asr     = "asr"
    case maghrib = "maghrib"
    case isya    = "isya"

    var displayName: String {
        switch self {
        case .subuh:   return "Fajr"
        case .zuhr:    return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isya:    return "Isha"
        }
    }

    var defaultTimeRange: (start: String, end: String) {
        switch self {
        case .subuh:   return ("04:30", "06:00")
        case .zuhr:    return ("12:15", "13:30")
        case .asr:     return ("15:45", "17:00")
        case .maghrib: return ("18:15", "19:15")
        case .isya:    return ("19:30", "20:45")
        }
    }
}