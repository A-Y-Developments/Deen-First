import SwiftUI

struct QuranReadingView: View {
    let surahId: Int
    @EnvironmentObject private var viewModel: QuranReadingViewModel
    @EnvironmentObject var router: Router

    var body: some View {
        Group {
                if viewModel.isLoading && viewModel.ayahs.isEmpty {
                    ProgressView()
                        .tint(.secondary400)
                } else {
                    mainContent
                }
            }
            .background(Color(hex: "062629").ignoresSafeArea())
            .searchable(text: $viewModel.searchQuery, prompt: "Search ayahs...")
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.searchAyahs()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "062629"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .errorAlert(isError: $viewModel.showError, errorMessage: $viewModel.errorMessage)
        .task {
            await viewModel.setup(with: surahId)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            horizontalSurahList
            surahInfoHeader
            ayahContent
        }
    }

    @ViewBuilder
    private var horizontalSurahList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(viewModel.allSurahs) { surah in
                        VStack(spacing: 6) {
                            Text(surah.englishName)
                                .font(.system(.callout))
                                .foregroundColor(
                                    viewModel.selectedSurah?.number == surah.number
                                    ? Color.secondary400
                                    : .white.opacity(0.6)
                                )
                                .padding(.bottom, 8)

                            Rectangle()
                                .fill(Color.secondary400)
                                .frame(height: 2)
                                .opacity(viewModel.selectedSurah?.number == surah.number ? 1 : 0)
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedSurah?.number)
                        .onTapGesture {
                            Task {
                                await viewModel.loadSurah(number: surah.number)
                            }
                        }
                        .id(surah.number)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .onChange(of: viewModel.selectedSurah) { _, newSurah in
                if let number = newSurah?.number {
                    proxy.scrollTo(number, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var surahInfoHeader: some View {
        if let surah = viewModel.selectedSurah {
            HStack {
                Text("\(surah.number). \(surah.englishName)")
                    .font(.system(.callout))
                    .foregroundColor(.black)

                Spacer()

                Text("\(surah.numberOfAyahs) Ayah, \(surah.revelationPlace)")
                    .font(.callout)
                    .foregroundColor(.black.opacity(0.8))
            }
            .padding()
            .background(Color.secondary400)
        }
    }

    @ViewBuilder
    private var ayahContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let surah = viewModel.selectedSurah, surah.number != 1 && surah.number != 9 {
                    bismillahView
                }

                if viewModel.filteredAyahs.isEmpty && !viewModel.searchQuery.isEmpty {
                    emptySearchView
                } else {
                    ForEach(Array(viewModel.filteredAyahs.enumerated()), id: \.element.id) { index, ayah in
                        ayahRow(for: ayah, index: index)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bismillahView: some View {
        Text("بِسْمِ ٱللَّٰهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
            .font(.system(size: 24))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(Color(hex: "062023"))
    }

    @ViewBuilder
    private var emptySearchView: some View {
        Text("No results")
            .foregroundColor(.white.opacity(0.6))
            .padding(.top, 40)
    }

    @ViewBuilder
    private func ayahRow(for ayah: Ayah, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(ayah.surahNo):\(ayah.numberInSurah)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "8E8E93"))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(ayah.text)
                .font(.system(size: 24))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.white)

            if !ayah.english.isEmpty {
                Text(ayah.english)
                    .font(.callout)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            index % 2 == 0
            ? Color(hex: "0e3034")
            : Color(hex: "062023")
        )
    }
}

#Preview {
    QuranReadingView(surahId: 1)
        .environmentObject(QuranReadingViewModel())
        .environmentObject(Router())
}
