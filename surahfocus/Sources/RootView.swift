//
//  RootView.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = Router()

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            HomeView()
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case .quran:
            Text("Quran View - Coming Soon")
                .navigationTitle("Quran")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            router.navigateBack()
                        }
                    }
                }
        }
    }
}

#Preview {
    RootView()
}
