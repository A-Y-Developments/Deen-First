//
//  Router.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import SwiftUI
import Combine

class Router: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Route: Hashable {
        case home
        case quran
    }

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func replaceNavigationPath(with routes: [Route]) {
        navigationPath = NavigationPath()
        routes.forEach { navigationPath.append($0) }
    }
}
