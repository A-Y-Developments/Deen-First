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
