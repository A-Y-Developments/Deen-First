import Foundation

enum BlockLimitType {
    case appLimit
    case timeLimit
}

struct BlockedAppInfo: Identifiable {
    let id: UUID
    let tokenData: Data
    let name: String
    let bundleId: String
    let timeLimit: TimeLimit
    let limitType: BlockLimitType

    init(
        id: UUID = UUID(),
        tokenData: Data,
        name: String = "App",
        bundleId: String = "",
        timeLimit: TimeLimit = .fifteenMin,
        limitType: BlockLimitType = .appLimit
    ) {
        self.id = id
        self.tokenData = tokenData
        self.name = name
        self.bundleId = bundleId
        self.timeLimit = timeLimit
        self.limitType = limitType
    }

    var displayName: String {
        name.isEmpty ? "App" : name
    }

    var timeLimitDisplay: String {
        timeLimit.displayName
    }
}
