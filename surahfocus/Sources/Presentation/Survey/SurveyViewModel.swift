import SwiftUI

@MainActor
final class SurveyViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var answers: SurveyAnswers = SurveyAnswers()

    var canGoNext: Bool {
        switch currentStep {
        case 1: return answers.phoneFrequency != nil
        case 2: return !answers.feelings.isEmpty
        case 3: return !answers.apps.isEmpty
        case 4: return answers.dailyHoursUsage != nil
        default: return false
        }
    }

    var canGoBack: Bool {
        currentStep > 1
    }

    var totalSteps: Int = 4

    func goNext() -> Bool {
        guard canGoNext else { return false }
        if currentStep < totalSteps {
            currentStep += 1
            return false
        }
        return true
    }

    func goBack() {
        if canGoBack {
            currentStep -= 1
        }
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
}
