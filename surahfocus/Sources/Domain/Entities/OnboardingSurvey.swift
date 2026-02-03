import Foundation

struct OnboardingSurvey: Codable {
    var motivations: Set<Motivation>
    var distractionTimes: Set<DistractionTime>
    var goals: Set<Goal>
    var isCompleted: Bool
    var completedAt: Date?

    enum Motivation: String, Codable, CaseIterable {
        case consistency = "I want more consistency with the Quran"
        case distracted = "I get distracted too easily"
        case routine = "I want a simple daily routine"
        case focus = "I need help focusing"
        case reconnect = "I want to reconnect with my faith"
    }

    enum DistractionTime: String, Codable, CaseIterable {
        case lateNight = "Late at night"
        case overwhelmed = "When I feel overwhelmed"
        case throughout = "Throughout the day"
        case stressed = "When I feel stressed"
        case quickCheck = "For a minute (turns into hours)"
    }

    enum Goal: String, Codable, CaseIterable {
        case quranConsistency = "More consistency with the Quran"
        case presence = "More presence and focus"
        case betterHabits = "Better phone habits"
    }

    init() {
        self.motivations = []
        self.distractionTimes = []
        self.goals = []
        self.isCompleted = false
        self.completedAt = nil
    }
}

final class SurveyStorage {
    private static let key = "onboarding_survey"

    static func save(_ survey: OnboardingSurvey) {
        if let encoded = try? JSONEncoder().encode(survey) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    static func load() -> OnboardingSurvey? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let survey = try? JSONDecoder().decode(OnboardingSurvey.self, from: data) else {
            return nil
        }
        return survey
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
