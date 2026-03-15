import SwiftUI

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var answers: SurveyAnswers = SurveyAnswers()

    let totalSteps: Int = 4

    var canGoBack: Bool { currentStep > 1 }

    var canGoNext: Bool {
        switch currentStep {
        case 1: return answers.phoneFrequency != nil
        case 2: return !answers.feelings.isEmpty
        case 3: return !answers.apps.isEmpty
        case 4: return answers.dailyHoursUsage != nil
        default: return false
        }
    }

    func goNext() -> Bool {
        guard canGoNext else { return false }
        if currentStep < totalSteps {
            currentStep += 1
            return false
        }
        return true
    }

    func goBack() {
        guard canGoBack else { return }
        currentStep -= 1
    }

    func setPhoneFrequency(_ value: String) {
        answers.phoneFrequency = value
    }

    func toggleFeeling(_ feeling: String) {
        if let index = answers.feelings.firstIndex(of: feeling) {
            answers.feelings.remove(at: index)
        } else {
            answers.feelings.append(feeling)
        }
    }

    func toggleApp(_ app: String) {
        if let index = answers.apps.firstIndex(of: app) {
            answers.apps.remove(at: index)
        } else {
            answers.apps.append(app)
        }
    }

    func setDailyHoursUsage(_ value: String) {
        answers.dailyHoursUsage = value
    }
}
