import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: ActiveSessionViewModel

    init(surahs: [SurahWithRange], ayahs: [Ayah] = []) {
        _viewModel = StateObject(wrappedValue: ActiveSessionViewModel(surahs: surahs, ayahs: ayahs))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { Task { await viewModel.endSession() } }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.ayahs.enumerated()), id: \.element.id) { index, ayah in
                                AyahRow(
                                    ayah: ayah,
                                    isActive: index == viewModel.currentAyahIndex,
                                    isPast: index < viewModel.currentAyahIndex
                                )
                                .id(ayah.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.currentAyahIndex) { oldValue, newIndex in
                        guard newIndex >= 0, newIndex < viewModel.ayahs.count else { return }
                        let currentAyah = viewModel.ayahs[newIndex]
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(currentAyah.id, anchor: .center)
                        }
                    }
                }

                VStack(spacing: 16) {
                    Text(currentSurahName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(viewModel.currentAyahIndex + 1) / \(viewModel.ayahs.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 32) {
                        Button(action: { Task { await viewModel.previousAyah() } }) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundColor(viewModel.currentAyahIndex > 0 ? .white : .white.opacity(0.3))
                        }
                        .disabled(viewModel.currentAyahIndex == 0)

                        Button(action: { viewModel.togglePlayPause() }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue)
                        }

                        Button(action: { Task { await viewModel.nextAyah() } }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(viewModel.currentAyahIndex < viewModel.ayahs.count - 1 ? .white : .white.opacity(0.3))
                        }
                        .disabled(viewModel.currentAyahIndex >= viewModel.ayahs.count - 1)
                    }

                    Text(sessionTimeString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.05))
            }
        }
        .navigationBarHidden(true)
        .alert("Astaghfirullah! Are you sure?", isPresented: $viewModel.showEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) {
                Task { await viewModel.confirmEndSession() }
            }
        } message: {
            Text("If you end this session, you need to restart again, focus for a little longer!")
        }
        .alert(viewModel.errorMessage ?? "Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        }
        .onAppear {
            viewModel.router = router
        }
        .task {
            await viewModel.startSession()
        }
    }

    private var currentSurahName: String {
        guard let currentAyah = viewModel.ayahs.first(where: { $0.numberInSurah == viewModel.currentAyahIndex + 1 }) else { return "" }
        return currentAyah.surahName
    }

    private var sessionTimeString: String {
        let minutes = Int(viewModel.sessionDuration) / 60
        let seconds = Int(viewModel.sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AyahRow: View {
    let ayah: Ayah
    let isActive: Bool
    let isPast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(ayah.numberInSurah)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(isActive ? Color.blue : Color.white.opacity(0.1)))

            VStack(alignment: .leading, spacing: 8) {
                Text(ayah.arabic1)
                    .font(.title3)
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))

                Text(ayah.english)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(isActive ? 0.8 : 0.3))
            }

            if isActive {
                Spacer()
                PlayingIndicator()
            }
        }
        .padding(16)
        .background(
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                }
                if !isActive && !isPast {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                }
            }
        )
        .opacity(isActive ? 1.0 : 0.5)
        .overlay(
            Group {
                if isActive {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                }
            }
        )
    }
}

private struct PlayingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4, height: 16)
                    .offset(y: offsetForIndex(index))
            }
        }
        .frame(height: 16)
        .onAppear { isAnimating = true }
    }

    private func offsetForIndex(_ index: Int) -> CGFloat {
        let time = isAnimating ? Date().timeIntervalSince1970 : 0
        return CGFloat(sin(Double(index) * .pi * 2 / 3 + time * 5)) * 4
    }
}

#Preview {
    NavigationStack {
        ActiveSessionView(
            surahs: [
                SurahWithRange(surah: Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Meccan"), startAyah: 1, endAyah: 7)
            ],
            ayahs: [
                Ayah(number: 1, text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", numberInSurah: 1, english: "In the name of Allah, the Entirely Merciful, the Especially Merciful", arabic1: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", surahNo: 1, surahName: "Al-Fatihah"),
                Ayah(number: 2, text: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", numberInSurah: 2, english: "All praise is due to Allah, Lord of the worlds", arabic1: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", surahNo: 1, surahName: "Al-Fatihah")
            ]
        )
    }
}
