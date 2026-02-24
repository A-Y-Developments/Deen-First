import SwiftUI

struct SurahListSheet: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchQuery, placeholder: "Search surahs...")
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            // Single ScrollView — no nesting because enableAppleScrollBehavior
            // is removed. This fixes both the glitch and the scroll cap.
            ScrollView {
                if viewModel.isLoading && viewModel.surahs.isEmpty {
                    ProgressView()
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
                        if viewModel.viewMode == .surah {
                            ForEach(viewModel.filteredSurahs) { surah in
                                SurahCard(surah: surah) {
                                    router.navigate(to: .quranReading(surahId: surah.number))
                                }
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text("Juz 1")
                                    .font(.system(.body, weight: .bold))
                                    .foregroundColor(Color(hex: "ADA666"))
                                ForEach(viewModel.filteredSurahs) { surah in
                                    SurahCard(surah: surah) {
                                        router.navigate(to: .quranReading(surahId: surah.number))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}