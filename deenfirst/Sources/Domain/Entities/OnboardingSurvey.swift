import Foundation

// MARK: - New Survey Enums matching SurveyStep1-4

enum PhoneDistractionFrequency: String, Codable, CaseIterable {
    case almostNever = "Almost Never"
    case sometimes = "Sometimes"
    case prettyOften = "Pretty often"
    case everyTime = "Every time I try"
}

enum PostScrollingFeeling: String, Codable, CaseIterable {
    case guilty = "Guilty and drained"
    case numb = "Numb"
    case exhausted = "Mentally exhausted"
    case indifferent = "Indifferent"
}

enum DistractionApp: String, Codable, CaseIterable {
    case socialMedia = "Social Media"
    case videoStreaming = "Video/Streaming"
    case games = "Games"
    case messaging = "Messaging"
    case news = "News"
}

// MARK: - Survey Answers for in-memory storage

struct SurveyAnswers: Codable, Hashable {
    var phoneFrequency: String?
    var feelings: [String]
    var apps: [String]
    var dailyHoursUsage: String?

    init() {
        self.phoneFrequency = nil
        self.feelings = []
        self.apps = []
        self.dailyHoursUsage = nil
    }
}

// MARK: - OnboardingSurvey (deprecated, kept for potential future use)

struct OnboardingSurvey: Codable {
    var phoneDistractionFrequency: PhoneDistractionFrequency?
    var postScrollingFeelings: Set<PostScrollingFeeling>
    var distractionApps: Set<DistractionApp>
    var isCompleted: Bool
    var completedAt: Date?

    init() {
        self.phoneDistractionFrequency = nil
        self.postScrollingFeelings = []
        self.distractionApps = []
        self.isCompleted = false
        self.completedAt = nil
    }
}
