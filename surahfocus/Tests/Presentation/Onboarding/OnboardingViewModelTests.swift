import XCTest
@testable import SurahFocus

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var viewModel: OnboardingViewModel!

    override func setUp() {
        viewModel = OnboardingViewModel()
        SurveyStorage.clear()
    }

    override func tearDown() {
        viewModel = nil
        SurveyStorage.clear()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertTrue(viewModel.survey.motivations.isEmpty)
        XCTAssertFalse(viewModel.canContinue)
    }

    func testProgressText() {
        XCTAssertEqual(viewModel.progressText, "1/4")
        viewModel.currentStep = 1
        XCTAssertEqual(viewModel.progressText, "2/4")
        viewModel.currentStep = 2
        XCTAssertEqual(viewModel.progressText, "3/4")
        viewModel.currentStep = 3
        XCTAssertEqual(viewModel.progressText, "4/4")
    }

    // MARK: - Step 1: Motivations Tests

    func testToggleMotivation() {
        let motivation = OnboardingSurvey.Motivation.consistency

        viewModel.toggleMotivation(motivation)
        XCTAssertTrue(viewModel.isMotivationSelected(motivation))
        XCTAssertTrue(viewModel.canContinue)

        viewModel.toggleMotivation(motivation)
        XCTAssertFalse(viewModel.isMotivationSelected(motivation))
        XCTAssertFalse(viewModel.canContinue)
    }

    func testMultipleMotivations() {
        viewModel.toggleMotivation(.consistency)
        viewModel.toggleMotivation(.focus)

        XCTAssertEqual(viewModel.survey.motivations.count, 2)
        XCTAssertTrue(viewModel.canContinue)
    }

    // MARK: - Step 2: Distraction Times Tests

    func testToggleDistractionTime() {
        viewModel.currentStep = 1
        let time = OnboardingSurvey.DistractionTime.lateNight

        viewModel.toggleDistractionTime(time)
        XCTAssertTrue(viewModel.isDistractionTimeSelected(time))
        XCTAssertTrue(viewModel.canContinue)
    }

    func testMultipleDistractionTimes() {
        viewModel.currentStep = 1
        viewModel.toggleDistractionTime(.lateNight)
        viewModel.toggleDistractionTime(.throughout)

        XCTAssertEqual(viewModel.survey.distractionTimes.count, 2)
    }

    // MARK: - Step 3: Goals Tests

    func testToggleGoal() {
        viewModel.currentStep = 2
        let goal = OnboardingSurvey.Goal.quranConsistency

        viewModel.toggleGoal(goal)
        XCTAssertTrue(viewModel.isGoalSelected(goal))
        XCTAssertTrue(viewModel.canContinue)
    }

    func testMultipleGoals() {
        viewModel.currentStep = 2
        viewModel.toggleGoal(.quranConsistency)
        viewModel.toggleGoal(.betterHabits)

        XCTAssertEqual(viewModel.survey.goals.count, 2)
    }

    // MARK: - Navigation Tests

    func testGoNextIncreasesStep() {
        viewModel.toggleMotivation(.consistency)
        viewModel.goNext()

        XCTAssertEqual(viewModel.currentStep, 1)
    }

    func testGoNextDisabledWithoutSelection() {
        viewModel.goNext()

        XCTAssertEqual(viewModel.currentStep, 0)
    }

    func testGoBackDecreasesStep() {
        viewModel.currentStep = 2
        viewModel.goBack()

        XCTAssertEqual(viewModel.currentStep, 1)
    }

    func testCannotGoBackFromFirstStep() {
        XCTAssertFalse(viewModel.canGoBack)

        viewModel.currentStep = 1
        XCTAssertTrue(viewModel.canGoBack)
    }

    func testSkipAdvancesStep() {
        viewModel.skip()
        XCTAssertEqual(viewModel.currentStep, 1)
    }

    // MARK: - Completion Tests

    func testCompleteSetsCompletionFlag() async {
        await viewModel.complete()

        XCTAssertTrue(viewModel.survey.isCompleted)
        XCTAssertNotNil(viewModel.survey.completedAt)
    }

    // MARK: - Persistence Tests

    func testSurveyPersistence() {
        viewModel.toggleMotivation(.consistency)
        viewModel.toggleMotivation(.focus)
        viewModel.toggleDistractionTime(.lateNight)
        viewModel.toggleGoal(.quranConsistency)

        // Create new viewModel and load
        let newViewModel = OnboardingViewModel()
        newViewModel.loadSavedSurvey()

        XCTAssertTrue(newViewModel.isMotivationSelected(.consistency))
        XCTAssertTrue(newViewModel.isMotivationSelected(.focus))
        XCTAssertTrue(newViewModel.isDistractionTimeSelected(.lateNight))
        XCTAssertTrue(newViewModel.isGoalSelected(.quranConsistency))
    }

    // MARK: - Continue Button State Tests

    func testContinueButtonState_Step1() {
        // Step 1: motivations
        XCTAssertFalse(viewModel.canContinue)

        viewModel.toggleMotivation(.consistency)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testContinueButtonState_Step2() {
        viewModel.currentStep = 1

        XCTAssertFalse(viewModel.canContinue)

        viewModel.toggleDistractionTime(.lateNight)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testContinueButtonState_Step3() {
        viewModel.currentStep = 2

        XCTAssertFalse(viewModel.canContinue)

        viewModel.toggleGoal(.quranConsistency)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testContinueButtonState_Step4() {
        // Navigate through steps to reach step 4
        // Step 1: Add motivation
        viewModel.toggleMotivation(.consistency)
        XCTAssertTrue(viewModel.canContinue)
        viewModel.goNext()
        XCTAssertEqual(viewModel.currentStep, 1)

        // Step 2: Add distraction time
        viewModel.toggleDistractionTime(.throughout)
        XCTAssertTrue(viewModel.canContinue)
        viewModel.goNext()
        XCTAssertEqual(viewModel.currentStep, 2)

        // Step 3: Add goal
        viewModel.toggleGoal(.quranConsistency)
        XCTAssertTrue(viewModel.canContinue)
        viewModel.goNext()
        XCTAssertEqual(viewModel.currentStep, 3) // Now at step 4 (index 3)

        // Step 4 (time comparison) always enabled
        XCTAssertTrue(viewModel.canContinue)
    }
}
