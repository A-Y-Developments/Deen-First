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
                    bottomSheetPosition: $bottomSheetPosition,
                    switchablePositions: [
                        .relative(0.55),
                        .relativeTop(0.95)
                    ]
                ) {
                    SurahListSheet()
                        .environmentObject(viewModel)
                        .environmentObject(router)
                }
                .customBackground(Color.primary900.cornerRadius(30))
                .customAnimation(
                    .interactiveSpring(
                        response: 0.28,
                        dampingFraction: 0.82,
                        blendDuration: 0.1
                    )
                )
                .dragIndicatorColor(Color.gray4.opacity(0.2))
                // REMOVED .enableAppleScrollBehavior() — it adds its own
                // ScrollView wrapper which nests with ours → scroll cap bug
                .tabItem { Label("Quran", systemImage: "book.fill") }
                .tag(0)
                
            BlockingTabView()
                .tabItem { Label("Blocking", systemImage: "nosign") }
                .tag(1)

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .accentColor(Color(hex: "ADA666"))
    }
}