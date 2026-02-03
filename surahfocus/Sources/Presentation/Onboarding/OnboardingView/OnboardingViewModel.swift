import SwiftUI
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var survey = OnboardingSurvey()
    @Published var canContinue = false
    @Published var isCompleting = false

    private let totalSteps = 4

    var progressText: String {
        "\(currentStep + 1)/\(totalSteps)"
    }

    var canGoBack: Bool {
        currentStep > 0
    }

    // MARK: - Step 1: Motivations

    func toggleMotivation(_ motivation: OnboardingSurvey.Motivation) {
        if survey.motivations.contains(motivation) {
            survey.motivations.remove(motivation)
        } else {
            survey.motivations.insert(motivation)
        }
        updateContinueState()
        saveSurvey()
    }

    func isMotivationSelected(_ motivation: OnboardingSurvey.Motivation) -> Bool {
        survey.motivations.contains(motivation)
    }

    // MARK: - Step 2: Distraction Times

    func toggleDistractionTime(_ time: OnboardingSurvey.DistractionTime) {
        if survey.distractionTimes.contains(time) {
            survey.distractionTimes.remove(time)
        } else {
            survey.distractionTimes.insert(time)
        }
        updateContinueState()
        saveSurvey()
    }

    func isDistractionTimeSelected(_ time: OnboardingSurvey.DistractionTime) -> Bool {
        survey.distractionTimes.contains(time)
    }

    // MARK: - Step 3: Goals

    func toggleGoal(_ goal: OnboardingSurvey.Goal) {
        if survey.goals.contains(goal) {
            survey.goals.remove(goal)
        } else {
            survey.goals.insert(goal)
        }
        updateContinueState()
        saveSurvey()
    }

    func isGoalSelected(_ goal: OnboardingSurvey.Goal) -> Bool {
        survey.goals.contains(goal)
    }

    // MARK: - Navigation

    func goNext() {
        guard canContinue else { return }

        if currentStep < totalSteps - 1 {
            currentStep += 1
            updateContinueState()
        }
    }

    func goBack() {
        if currentStep > 0 {
            currentStep -= 1
            updateContinueState()
        }
    }

    func skip() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
            updateContinueState()
        }
    }

    func complete() async {
        isCompleting = true
        defer { isCompleting = false }

        survey.isCompleted = true
        survey.completedAt = Date()
        saveSurvey()

        // Update user's onboarding flag
        do {
            if let user = try await DIContainer.shared.userRepository.getCurrentUser() {
                user.hasCompletedOnboarding = true
                try await DIContainer.shared.userRepository.updateUser(user)
            }
        } catch {
            print("Failed to update user onboarding status: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func updateContinueState() {
        switch currentStep {
        case 0: // Motivations
            canContinue = !survey.motivations.isEmpty
        case 1: // Distraction times
            canContinue = !survey.distractionTimes.isEmpty
        case 2: // Goals
            canContinue = !survey.goals.isEmpty
        case 3: // Time comparison (always enabled)
            canContinue = true
        default:
            canContinue = false
        }
    }

    private func saveSurvey() {
        SurveyStorage.save(survey)
    }

    func loadSavedSurvey() {
        if let saved = SurveyStorage.load() {
            survey = saved
            updateContinueState()
        }
    }
}
