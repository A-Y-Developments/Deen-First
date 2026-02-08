import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel

    var body: some View {
        ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let user = viewModel.user {
                                HStack {
                                    Text("As-salamu alaykum,")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                    if let name = user.name {
                                        Text(name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                            }

                            if viewModel.currentStreak > 0 {
                                StreakBadge(streak: viewModel.currentStreak)
                                    .padding(.horizontal, 24)
                            }

                            SearchBar(text: $viewModel.searchQuery, placeholder: "Search surahs...")
                                .padding(.horizontal, 24)

                            if viewModel.isLoading && viewModel.surahs.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.filteredSurahs) { surah in
                                        SurahCard(surah: surah) {
                                            router.navigate(to: .surahDetail(surahId: surah.number))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.loadSurahs()
                    }
                }
            }
        .navigationTitle("Quran")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .listenSession)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Color(hex: "4facfe"))
                }
            }
        }
        .errorAlert(isError: $viewModel.showError, errorMessage: $viewModel.errorMessage)
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}
