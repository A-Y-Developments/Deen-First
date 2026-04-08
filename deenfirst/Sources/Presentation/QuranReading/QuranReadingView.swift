import SwiftUI

struct QuranReadingView: View {
    let surahId: Int
    @EnvironmentObject private var viewModel: QuranReadingViewModel
    @EnvironmentObject var router: Router
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        Group {
                if viewModel.isLoading && viewModel.ayahs.isEmpty {
                    ProgressView()
                        .tint(.secondary400)
                } else {
                    mainContent
                }
            }
            .background(Color.primary900.ignoresSafeArea())
            .searchable(text: $viewModel.searchQuery, prompt: "Search ayahs...")
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.searchAyahs()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.primary900, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .errorAlert(isError: $viewModel.showError, errorMessage: $viewModel.errorMessage)
        .onDisappear {
            viewModel.stopAudio()
            viewModel.recordReadingSession()
        }
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
                            Text(surah.name)
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
                Text("\(surah.number). \(surah.name)")
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
        ScrollViewReader { proxy in
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
                .id("ayahContent")
            }
            .onChange(of: viewModel.selectedSurah) { _, _ in
                viewModel.stopAudio()
                withAnimation {
                    proxy.scrollTo("ayahContent", anchor: .top)
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
            .background(Color.primary500.opacity(0.3))
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
            HStack(spacing: 6) {
                Text("\(ayah.surahNo):\(ayah.numberInSurah)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray4)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Button {
                    Task { await viewModel.playAyah(ayah) }
                } label: {
                    Image(systemName: viewModel.playingAyahId == ayah.uniqueScrollID && viewModel.isPlayingAudio
                        ? "speaker.wave.2.fill"
                        : "speaker.fill")
                        .font(.callout)
                        .foregroundColor(.secondary400)
                }
                .buttonStyle(.plain)
            }

            Text(ayah.text)
                .font(.system(size: 24))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.white)

            if !ayah.transliteration.isEmpty {
                Text(ayah.transliteration)
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            let translationText = viewModel.getTranslation(for: ayah)
            if !translationText.isEmpty {
                Text(translationText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            index % 2 == 0
            ? Color.primary500.opacity(0.3)
            : Color.primary500.opacity(0.2)
        )
    }
}

#Preview {
    QuranReadingView(surahId: 1)
        .environmentObject(QuranReadingViewModel())
        .environmentObject(Router())
}
