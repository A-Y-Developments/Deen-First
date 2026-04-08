import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: ActiveSessionViewModel
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @State private var isUserScrolling = false

    let surahs: [SurahWithRange]
    let ayahs: [Ayah]
    let isUnblockSession: Bool
    let unlockRuleId: UUID?

    init(surahs: [SurahWithRange], ayahs: [Ayah], isUnblockSession: Bool = false, unlockRuleId: UUID? = nil) {
        self.surahs = surahs
        self.ayahs = ayahs
        self.isUnblockSession = isUnblockSession
        self.unlockRuleId = unlockRuleId
    }

    var body: some View {
        ZStack {
            // Background
            Color.primary900.ignoresSafeArea()

            // Full screen ScrollView
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.ayahs.indices, id: \.self) { index in
                            let ayah = viewModel.ayahs[index]
                            ActiveAyahCard(
                                ayah: ayah,
                                surahNumber: ayah.surahNo,
                                isActive: index == viewModel.currentAyahIndex && !isUserScrolling,
                                translation: viewModel.getTranslation(for: ayah)
                            )
                            .id(ayah.uniqueScrollID)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 100)
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            isUserScrolling = true
                        }
                )
                .onChange(of: viewModel.currentAyahIndex) { oldValue, newIndex in
                    guard newIndex >= 0, newIndex < viewModel.ayahs.count else { return }
                    let currentAyah = viewModel.ayahs[newIndex]
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isUserScrolling = false
                        proxy.scrollTo(currentAyah.uniqueScrollID, anchor: .center)
                    }
                }
                .onAppear {
                    if let firstAyah = viewModel.ayahs.first {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            proxy.scrollTo(firstAyah.uniqueScrollID, anchor: .center)
                        }
                    }
                }
            }

            // Floating close button
            VStack {
                HStack {
                    Spacer()

                    Button(action: { Task { await viewModel.endSession() } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()

                Spacer()

                // Floating bottom player
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentSurahName)
                            .font(.system(.headline))
                            .foregroundColor(.white)

                        Text(currentSurahEnglishName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: { viewModel.togglePlayPause() }) {
                        Image(
                            systemName: viewModel.isPlaying
                                ? "pause.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 44))
                        .foregroundColor(Color.secondary200)
                    }
                }
                .padding()
                .background(Color.primary500)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding()
            }
        }
        .navigationBarHidden(true)
        .alert("Astaghfirullah! Are you sure?", isPresented: $viewModel.showEndConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("End", role: .destructive) {
                Task { await viewModel.confirmEndSession() }
            }
        } message: {
            Text("If you end this session, you need to restart again, focus for a little longer!")
        }
        .onChange(of: viewModel.sessionDidEnd) { _, newValue in
            if newValue {
                if isUnblockSession && !viewModel.unblockGranted {
                    // Early exit from unblock session — no access granted
                    router.navigateBack()
                } else {
                    router.navigate(
                        to: .sessionFinish(
                            duration: viewModel.sessionDuration,
                            surahCount: viewModel.surahs.count
                        )
                    )
                }
            }
        }
        .alert(
            viewModel.errorMessage ?? "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        }
        .alert("Audio Unavailable", isPresented: $viewModel.showUnblockFallback) {
            Button("Recite 1 Ayah (5 min)") {
                reciteToUnblockViewModel.targetRuleId = unlockRuleId
                reciteToUnblockViewModel.unblockDurationMinutes = 5
                router.navigate(to: .reciteToUnlock)
            }
            Button("Recite 2 Ayahs (10 min)") {
                reciteToUnblockViewModel.targetRuleId = unlockRuleId
                reciteToUnblockViewModel.unblockDurationMinutes = 10
                router.navigate(to: .reciteToUnlock)
            }
            Button("Cancel", role: .cancel) {
                router.navigateBack()
            }
        } message: {
            Text("Could not load audio. You can still unblock by reciting instead.")
        }
        .task {
            viewModel.configure(surahs: surahs, ayahs: ayahs, isUnblockSession: isUnblockSession, unlockRuleId: unlockRuleId)
            await viewModel.startSession()
        }
    }

    private var currentAyah: Ayah? {
        guard viewModel.currentAyahIndex < viewModel.ayahs.count else { return nil }
        return viewModel.ayahs[viewModel.currentAyahIndex]
    }

    private var currentSurahName: String {
        currentAyah?.surahName ?? ""
    }

    private var currentSurahEnglishName: String {
        guard let surahNo = currentAyah?.surahNo else { return "" }
        return viewModel.surahs.first(where: { $0.surah.number == surahNo })?.surah
            .englishNameTranslation ?? ""
    }
}

struct ActiveAyahCard: View {
    let ayah: Ayah
    let surahNumber: Int
    let isActive: Bool
    let translation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ayah number badge
            Text("\(surahNumber):\(ayah.numberInSurah)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "8E8E93"))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Arabic text
            Text(ayah.arabic1)
                .font(.system(size: 26, design: .serif))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.white)

            if !ayah.transliteration.isEmpty {
                Text(ayah.transliteration)
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Translation
            Text(translation)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.primary500.opacity(isActive ? 0.5 : 0.3))
        .opacity(isActive ? 1 : 0.3)
        .blur(radius: isActive ? 0 : 2)
        .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

#Preview {
    NavigationStack {
        ActiveSessionView(surahs: [], ayahs: [])
            .environmentObject(ActiveSessionViewModel())
            .environmentObject(Router())
            .environmentObject(ReciteToUnblockViewModel())
    }
}
