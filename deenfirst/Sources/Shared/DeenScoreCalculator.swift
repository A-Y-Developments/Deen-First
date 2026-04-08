import Foundation

// MARK: - Input

struct DeenScoreInput {
    let quranSeconds: Int
    let focusSessions: Int
    let recitationsPassed: Int
    let streakDays: Int
    let screenTimeOverLimitSeconds: Int
    let emergencyUnblocksThisWeek: Int
}

// MARK: - Weights

enum ScoreWeights {
    static let base = 50

    // Quran time thresholds (seconds) and awards
    static let quranTier1Seconds = 10 * 60
    static let quranTier2Seconds = 20 * 60
    static let quranTier3Seconds = 30 * 60
    static let quranTier1Points = 5
    static let quranTier2Points = 10
    static let quranTier3Points = 15
    static let quranTier4Points = 20

    // Focus sessions
    static let focusOneSessionPoints = 10
    static let focusTwoPlusSessionsPoints = 15

    // Recitations passed
    static let recitationOnePoints = 5
    static let recitationThreePlusPoints = 10

    // Streak
    static let streakActivePoints = 5
    static let streakWeekBonusPoints = 5
    static let streakBonusThresholdDays = 7

    // Over-limit penalties (seconds)
    static let overLimitTier1Seconds = 30 * 60
    static let overLimitTier2Seconds = 60 * 60
    static let overLimitTier3Seconds = 90 * 60
    static let overLimitTier1Penalty = -10
    static let overLimitTier2Penalty = -20
    static let overLimitTier3Penalty = -30

    // Emergency unblocks
    static let emergencyOnePenalty = -5
    static let emergencyTwoPlusPenalty = -10

    // Clamp bounds
    static let minScore = 0
    static let maxScore = 100
}

// MARK: - Calculator

/// Pure function — computes Deen Score (0–100) from daily/weekly input metrics.
/// No side effects, no external dependencies. Safe to call from main app and
/// `DeenFirstActivityReport` extension.
func calculateDeenScore(_ input: DeenScoreInput) -> Int {
    var score = ScoreWeights.base

    score += quranTimePoints(seconds: input.quranSeconds)
    score += focusSessionPoints(count: input.focusSessions)
    score += recitationPoints(count: input.recitationsPassed)
    score += streakPoints(days: input.streakDays)
    score += overLimitPenalty(seconds: input.screenTimeOverLimitSeconds)
    score += emergencyUnblockPenalty(count: input.emergencyUnblocksThisWeek)

    return min(ScoreWeights.maxScore, max(ScoreWeights.minScore, score))
}

// MARK: - Component scoring (private, pure)

private func quranTimePoints(seconds: Int) -> Int {
    if seconds <= 0 { return 0 }
    if seconds < ScoreWeights.quranTier1Seconds { return ScoreWeights.quranTier1Points }
    if seconds < ScoreWeights.quranTier2Seconds { return ScoreWeights.quranTier2Points }
    if seconds < ScoreWeights.quranTier3Seconds { return ScoreWeights.quranTier3Points }
    return ScoreWeights.quranTier4Points
}

private func focusSessionPoints(count: Int) -> Int {
    if count <= 0 { return 0 }
    if count == 1 { return ScoreWeights.focusOneSessionPoints }
    return ScoreWeights.focusTwoPlusSessionsPoints
}

private func recitationPoints(count: Int) -> Int {
    if count <= 0 { return 0 }
    if count < 3 { return ScoreWeights.recitationOnePoints }
    return ScoreWeights.recitationThreePlusPoints
}

private func streakPoints(days: Int) -> Int {
    if days <= 0 { return 0 }
    var points = ScoreWeights.streakActivePoints
    if days >= ScoreWeights.streakBonusThresholdDays {
        points += ScoreWeights.streakWeekBonusPoints
    }
    return points
}

private func overLimitPenalty(seconds: Int) -> Int {
    if seconds < ScoreWeights.overLimitTier1Seconds { return 0 }
    if seconds < ScoreWeights.overLimitTier2Seconds { return ScoreWeights.overLimitTier1Penalty }
    if seconds < ScoreWeights.overLimitTier3Seconds { return ScoreWeights.overLimitTier2Penalty }
    return ScoreWeights.overLimitTier3Penalty
}

private func emergencyUnblockPenalty(count: Int) -> Int {
    if count <= 0 { return 0 }
    if count == 1 { return ScoreWeights.emergencyOnePenalty }
    return ScoreWeights.emergencyTwoPlusPenalty
}
