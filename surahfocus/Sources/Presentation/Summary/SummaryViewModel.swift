import SwiftUI

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var answers: SurveyAnswers = SurveyAnswers()

    // Dynamic hours based on phone frequency
    var calculatedHours: String {
        switch answers.phoneFrequency {
        case "everyTime": return "4.5"
        case "prettyOften": return "3.0"
        case "sometimes": return "2.0"
        case "almostNever": return "1.0"
        default: return "2.5"
        }
    }

    func goNext() {
        if currentStep < 2 { currentStep += 1 }
    }

    func goBack() {
        if currentStep > 1 { currentStep -= 1 }
    }
}
