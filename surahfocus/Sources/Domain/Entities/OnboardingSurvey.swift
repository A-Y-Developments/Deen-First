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

enum LifeImpact: String, Codable, CaseIterable {
    case veryMuch = "Very Much"
    case prettyMuch = "Pretty Much"
    case little = "Yes, a little"
    case notAtAll = "Not at all"
}

// MARK: - Survey Answers for in-memory storage

struct SurveyAnswers: Codable, Hashable {
    var phoneFrequency: String?
    var feelings: [String]
    var apps: [String]
    var lifeImpact: String?

    init() {
        self.phoneFrequency = nil
        self.feelings = []
        self.apps = []
        self.lifeImpact = nil
    }
}

// MARK: - OnboardingSurvey (deprecated, kept for potential future use)

struct OnboardingSurvey: Codable {
    var phoneDistractionFrequency: PhoneDistractionFrequency?
    var postScrollingFeelings: Set<PostScrollingFeeling>
    var distractionApps: Set<DistractionApp>
    var lifeImpact: LifeImpact?
    var isCompleted: Bool
    var completedAt: Date?

    init() {
        self.phoneDistractionFrequency = nil
        self.postScrollingFeelings = []
        self.distractionApps = []
        self.lifeImpact = nil
        self.isCompleted = false
        self.completedAt = nil
    }
}
