import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case auth
        case onboarding
        case paywall
        case screenTimePermission
        case appSelection
        case appLimitSetup
        case downtimeSetup
        case mainTabs
        case surahDetail(surahId: Int)
        case listenSession
        // Blocks View
        case blocks
        case appLimit
        case timeLimit
        
        case focusSection
        case selectSurah(surahs: [SurahWithRange])
        case ayahRange(surah: Surah)
        case downloadModal(surahs: [SurahWithRange])
        case activeSession(surahs: [SurahWithRange], ayahs: [Ayah])
        case sessionFinish(duration: TimeInterval, surahCount: Int)
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
        navigationPath = NavigationPath()
        routes.forEach { navigationPath.append($0) }
    }

    func reset() {
        navigationPath = NavigationPath()
    }
}
