import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Quran")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            SearchBar(text: $viewModel.searchQuery, placeholder: "Search surahs...")
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            ScrollView {
                if viewModel.isLoading && viewModel.surahs.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)

                } else if !viewModel.searchQuery.isEmpty && viewModel.filteredSurahs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(Color.secondary300.opacity(0.6))

                        Text("No Result for \"\(viewModel.searchQuery)\"")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Check the spelling or try a new search.")
                            .font(.footnote)
                            .foregroundColor(Color.gray4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredSurahs) { surah in
                            SurahCard(surah: surah) {
                                router.navigate(to: .quranReading(surahId: surah.number))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }
            }
        }
        .mainBackground()
        .navigationBarHidden(true)
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
            await viewModel.requestNotificationPermission()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}
