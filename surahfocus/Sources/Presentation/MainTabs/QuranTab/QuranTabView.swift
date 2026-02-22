import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    @EnvironmentObject var settingsViewModel: SettingsTabViewModel

    var body: some View {
        VStack {
                Text("As-salamu alaykum, \(settingsViewModel.displayName.components(separatedBy: " ").first ?? "")!")
                    .font(.system(.title2, design: .serif))
                    .italic()
                    .foregroundColor(.white)
                    .padding(.top, 124)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                
                VStack {
                    HStack(spacing: -4) {
                        Image("fire")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64)
                        Text("0 days")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "AEF29B"))
                    }
                    .padding(.trailing, 16)
                    
                    Text("Start a new streak")
                        .font(.system(.footnote))
                        .foregroundStyle(Color(hex: "DBDABD"))
                }
                
                Button {
                   router.navigate(to: .focusSection)
                   // NOTES: FOR TEST ONLY, FIRE NOTIFICATION
                    // let content = UNMutableNotificationContent()
                    // content.title = "Test"
                    // content.body = "Notification works"
                    // content.sound = .default
                    // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    // UNUserNotificationCenter.current().add(
                    //     UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
                    // )
                } label: {
                    Text("Start Focus Session")
                        .padding(.vertical)
                        .padding(.horizontal, 48)
                        .background(Color.white)
                        .foregroundColor(Color.primary600)
                        .font(.system(.body, weight: .semibold))
                        .clipShape(Capsule())
                }
                .padding(.top, 32)
                .shadow(
                    color: Color.primary400,
                    radius: 12
                )
                
                Spacer()
        }
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
        .background {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
            await settingsViewModel.loadUserData()
        }
        .onChange(of: viewModel.searchQuery) { oldValue, newValue in
            viewModel.searchSurahs()
        }
    }
}

