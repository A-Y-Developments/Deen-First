import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            QuranTabView()
                .tabItem {
                    Label("Quran", systemImage: "book.fill")
                }
                .tag(0)

            BlockingTabView()
                .tabItem {
                    Label("Blocking", systemImage: "shield.fill")
                }
                .tag(1)

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "4facfe"))
    }
}
