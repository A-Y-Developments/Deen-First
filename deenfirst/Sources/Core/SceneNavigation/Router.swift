import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case auth
        case paywall(isFromSettings: Bool = false, currentPlan: String? = nil)
        case permissionSetup
        case setupAppToBlock
        case setupSummary
        case mainTabs
        case quranReading(surahId: Int)
        case blocks
        case appLimit
        case timeLimit
        case editAppLimit(id: UUID)
        case editTimeLimit(id: UUID)
        case focusSection(unlockRuleId: UUID? = nil)
        case selectSurah(surahs: [SurahWithRange])
        case ayahRange(surah: Surah)
        case activeSession(surahs: [SurahWithRange], ayahs: [Ayah], isUnblockSession: Bool, unlockRuleId: UUID?)
        case sessionFinish(duration: TimeInterval, surahCount: Int)
        case survey(step: Int, answers: SurveyAnswers)
        case calculateSurvey(answers: SurveyAnswers)
        case summary(step: Int, answers: SurveyAnswers)
        case howAppWork(step: Int)
        case finalSummary
        case subscription
        case preferences
        case support
        case reciteToUnlock
        case emergencyUnblock
        case dashboard
        case ayahPool
        case ayahPoolSurahPicker
        case unblockDurationSelection(ruleId: UUID)
    }

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func replaceWith(_ route: Route) {
        navigationPath = NavigationPath()
        navigationPath.append(route)
    }

    func replaceWith(_ routes: [Route]) {
        var newPath = NavigationPath()
        for route in routes {
            newPath.append(route)
        }
        navigationPath = newPath
    }

    func reset() {
        navigationPath = NavigationPath()
    }
}
