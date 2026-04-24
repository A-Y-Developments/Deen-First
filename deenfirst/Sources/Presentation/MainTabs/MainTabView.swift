import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(
                onViewAllSurahs: {
                    selectedTab = 1
                },
                onViewAllBlocks: {
                    selectedTab = 2
                }
            )
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            QuranTabView()
                .tabItem { Label("Quran", systemImage: "book.fill") }
                .tag(1)
                
            BlockingTabView()
                .tabItem { Label("Blocking", systemImage: "nosign") }
                .tag(2)

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .accentColor(Color(hex: "ADA666"))
    }
}
