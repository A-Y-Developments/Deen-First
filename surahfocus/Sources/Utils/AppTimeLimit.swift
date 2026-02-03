import Foundation

enum TimeLimit: Int, CaseIterable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninety = 90
    case oneHundredTwenty = 120

    var displayName: String {
        switch self {
        case .fifteen: return "15 min"
        case .thirty: return "30 min"
        case .fortyFive: return "45 min"
        case .sixty: return "1 hour"
        case .ninety: return "1.5 hours"
        case .oneHundredTwenty: return "2 hours"
        }
    }

    var minutes: Int {
        return self.rawValue
    }
}
