import SwiftUI
import BottomSheet

struct MainTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    @State private var selectedTab = 1
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.55)
    
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
