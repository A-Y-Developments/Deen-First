import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    @EnvironmentObject var settingsViewModel: SettingsTabViewModel

    var body: some View {
        GeometryReader { geo in
            // Sheet is at .relative(0.55), hero lives in top 45%
            let availableHeight = geo.size.height * 0.45

            VStack(spacing: 0) {
                Spacer()

                // All hero content grouped tightly together
                VStack(spacing: 16) {
                    Text("As-salamu alaykum, \(settingsViewModel.displayName.components(separatedBy: " ").first ?? "")!")
                        .font(.system(.title2, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    VStack(spacing: 4) {
                        HStack(spacing: -4) {
                            Image("fire")
                                .resizable()
                                .scaledToFit()
                                .frame(width: min(64, geo.size.height * 0.072))
                            Text("\(viewModel.currentStreak) day\(viewModel.currentStreak == 1 ? "" : "s")")
                                .font(.system(
                                    size: min(32, geo.size.height * 0.038),
                                    weight: .bold
                                ))
                                .foregroundStyle(Color(hex: "AEF29B"))
                        }
                        .padding(.trailing, 16)

                        Text(viewModel.currentStreak == 0 ? "Start a new streak" : "Keep your streak going!")
                            .font(.system(.footnote))
                            .foregroundStyle(Color(hex: "DBDABD"))
                    }

                    Button {
                        router.navigate(to: .focusSection)
                    } label: {
                        Text("Start Focus Session")
                            .padding(.vertical, 14)
                            .padding(.horizontal, 48)
                            .background(Color.white)
                            .foregroundColor(Color.primary600)
                            .font(.system(.body, weight: .semibold))
                            .clipShape(Capsule())
                    }
                    .shadow(color: Color.primary400, radius: 12)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: availableHeight * 0.08)
            }
            // Constrain VStack to only the available hero area,
            // not the full screen height
            .frame(width: geo.size.width, height: availableHeight)
            .padding(.top, geo.safeAreaInsets.top)
        }
        .mainBackground()
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
            await settingsViewModel.loadUserData()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}