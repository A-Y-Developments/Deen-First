import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case auth
        case paywall
        // Setup flow routes
        case permissionSetup
        case setupAppToBlock
        case setupSummary
        case mainTabs
        case surahDetail(surahId: Int)
        // Blocks View
        case blocks
        case appLimit
        case timeLimit
        case editAppLimit(id: UUID)
        case editTimeLimit(id: UUID)
        case editAllDay(id: UUID)

        case focusSection
        case selectSurah(surahs: [SurahWithRange])
        case ayahRange(surah: Surah)
        case activeSession(surahs: [SurahWithRange], ayahs: [Ayah])
        case sessionFinish(duration: TimeInterval, surahCount: Int)

        // NEW: Survey flow with data passing via associated values
        case survey(step: Int, answers: SurveyAnswers)
        case calculateSurvey(answers: SurveyAnswers)
        case summary(step: Int, answers: SurveyAnswers)
        case howAppWork(step: Int)
        case finalSummary
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
