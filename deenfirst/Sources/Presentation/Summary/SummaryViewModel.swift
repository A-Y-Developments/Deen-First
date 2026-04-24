import SwiftUI

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var answers: SurveyAnswers = SurveyAnswers()
    @Published var progress: CGFloat = 0.0
    @Published var percentage: Int = 0
    @Published var isCalculating: Bool = true
    @Published var ellipsisCount: Int = 0

    private var progressBarWidth: CGFloat = 0
    private var ellipsisTask: Task<Void, Never>?

    // Exact range label from user selection
    var selectedRangeLabel: String {
        guard let usage = answers.dailyHoursUsage else { return "" }
        switch usage {
        case "veryMuch": return "1-2"
        case "prettyMuch": return "2-4"
        case "little": return "4-6"
        case "notAtAll": return "6-8"
        case "moreThan8": return "> 8"
        default: return ""
        }
    }

    // Formatted app names for display
    var selectedAppsDisplay: String {
        let appNames: [String: String] = [
            "socialMedia": "social media",
            "videoStreaming": "video/streaming",
            "games": "games",
            "messaging": "messaging",
            "news": "news"
        ]
        let names = answers.apps.compactMap { appNames[$0] }

        if names.isEmpty { return "these apps" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return "\(names[0]) and \(names[1])" }

        let allButLast = names.dropLast().joined(separator: ", ")
        guard let last = names.last else { return allButLast }
        return "\(allButLast), and \(last)"
    }

    // MARK: - Achievement Calculations

    // Juz count based on hours (1 Juz ≈ 30-60 min for average reader)
    var juzAchievement: String {
        guard let usage = answers.dailyHoursUsage else { return "1-2" }
        switch usage {
        case "veryMuch": return "1-2"      // 1-2 hours
        case "prettyMuch": return "2-3"    // 2-4 hours
        case "little": return "3-5"        // 4-6 hours
        case "notAtAll": return "5-7"      // 6-8 hours
        case "moreThan8": return "7+"      // > 8 hours
        default: return "1-2"
        }
    }

    // Pages count (1 Juz ≈ 20 pages)
    var pagesAchievement: String {
        guard let usage = answers.dailyHoursUsage else { return "~30" }
        switch usage {
        case "veryMuch": return "~30"      // ~1.5 Juz
        case "prettyMuch": return "~50"    // ~2.5 Juz
        case "little": return "~80"        // ~4 Juz
        case "notAtAll": return "~120"     // ~6 Juz
        case "moreThan8": return "~140+"   // ~7+ Juz
        default: return "~30"
        }
    }

    // Surah memorization progress
    var surahAchievement: String {
        guard let usage = answers.dailyHoursUsage else { return "Start learning" }
        switch usage {
        case "veryMuch": return "Start learning a Surah"
        case "prettyMuch": return "Memorize 1 Surah"
        case "little": return "Memorize 1-2 Surahs"
        case "notAtAll": return "Memorize 2 Surahs"
        case "moreThan8": return "Memorize 2-3 Surahs"
        default: return "Start learning"
        }
    }

    // Description for pages achievement
    var pagesDescription: String {
        return "Finished \(pagesAchievement) pages of Quran"
    }

    func goNext() {
        if currentStep < 2 { currentStep += 1 }
    }

    func goBack() {
        if currentStep > 1 { currentStep -= 1 }
    }

    // MARK: - Calculation Animation

    /// Runs the 5-second calculation animation: progress bar, percentage count, ellipsis cycle.
    /// Completes when the 100% mark is reached; caller navigates after await.
    func startCalculation(screenWidth: CGFloat) async {
        progressBarWidth = screenWidth - 144
        isCalculating = true
        progress = 0
        percentage = 0

        withAnimation(.linear(duration: 5)) {
            progress = progressBarWidth
        }

        ellipsisTask?.cancel()
        ellipsisTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else { return }
                self.ellipsisCount = (self.ellipsisCount + 1) % 4
            }
        }

        for i in 1...100 {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { break }
            percentage = i
        }

        ellipsisTask?.cancel()
        ellipsisTask = nil
        isCalculating = false
    }
}
