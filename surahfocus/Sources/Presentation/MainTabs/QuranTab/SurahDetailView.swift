import SwiftUI

struct SurahDetailView: View {
    let surahNumber: Int
    @StateObject private var viewModel: SurahDetailViewModel

    init(surahNumber: Int) {
        self.surahNumber = surahNumber
        self._viewModel = StateObject(wrappedValue: SurahDetailViewModel(surahNumber: surahNumber))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.ayahs.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else if let surah = viewModel.surah {
                        SurahHeader(surah: surah)
                            .padding(.horizontal, 16)

                        if surah.number != 1 && surah.number != 9 {
                            BismillahView()
                                .padding(.horizontal, 16)
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.ayahs) { ayah in
//                                AyahCard(ayah: ayah, showTranslation: viewModel.showTranslation)
                                Text(ayah.text)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80)
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(viewModel.surah?.surahNameArabicLong ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleTranslation()
                } label: {
                    Image(systemName: viewModel.showTranslation ? "text.bubble.fill" : "text.bubble")
                        .foregroundColor(Color(hex: "4facfe"))
                }
            }
        }
        .errorAlert(isError: $viewModel.showError, errorMessage: $viewModel.errorMessage)
        .task {
            if viewModel.ayahs.isEmpty {
                await viewModel.loadSurahDetail()
            }
        }
    }
}
