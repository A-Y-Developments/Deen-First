import SwiftUI
import BottomSheet

struct MainTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    @State private var selectedTab = 0
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.55)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuranTabView()
                .bottomSheet(
                    bottomSheetPosition: self.$bottomSheetPosition,
                    switchablePositions: [
                        .relative(0.55),
                        .relativeTop(0.95)
                    ]
                ) {
                    SurahListSheet()
                        .environmentObject(viewModel)
                        .environmentObject(router)
                }
                .tabItem {
                    Label("Quran", systemImage: "book.fill")
                }
                .tag(0)
            BlockingTabView()
                .tabItem {
                    Label("Blocking", systemImage: "nosign")
                }
                .tag(1)

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "ADA666"))
    }
}

#Preview {
    MainTabView()
        .environmentObject(Router())
        .environmentObject(QuranTabViewModel())
}
