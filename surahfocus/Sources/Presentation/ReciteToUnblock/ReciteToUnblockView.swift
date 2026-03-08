import AVFoundation
import SwiftUI



struct ReciteToUnblockView: View {
    @EnvironmentObject private var viewModel: ReciteToUnblockViewModel
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#0B2016"),
                    Color(hex: "#0F2C1E"),
                    Color(hex: "#133524"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                Group {
                    switch viewModel.state {
                    case .loadingAyah, .idle:
                        loadingView
                    case .error(let msg):
                        errorView(message: msg)
                    case .ready, .recording, .transcribing:
                        reciteContent
                    case .result(let passed, let score):
                        resultContent(passed: passed, score: score)
                    }
                }

                Spacer()

                bottomActionArea
                    .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.stopAudio()
        }
        .task {
            await viewModel.loadRandomAyah()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white.opacity(0.5))
            Text("Loading ayah...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.35))
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.loadRandomAyah() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - Recite Content

    private var reciteContent: some View {
        VStack(spacing: 0) {
            Text("Recite this ayah")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 6)

            if let ayah = viewModel.ayah {
                Text("\(ayah.surahName) \(ayah.surahNo):\(ayah.numberInSurah)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ADE80"))
                    .padding(.bottom, 36)
            }

            if let ayah = viewModel.ayah {
                ayahCard(ayah: ayah)
                    .padding(.horizontal, 24)
            }

            if case .transcribing = viewModel.state {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color(hex: "#4ADE80"))
                        .scaleEffect(0.8)
                    Text("Checking your recitation...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.top, 24)
            }
        }
    }

    // MARK: - Ayah Card

    private func ayahCard(ayah: Ayah) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(ayah.surahNo):\(ayah.numberInSurah)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.1)))

                Spacer()

                if case .ready = viewModel.state {
                    Button {
                        Task { await viewModel.playAyahAudio() }
                    } label: {
                        Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.2.fill" : "speaker.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Button {
                        Task { await viewModel.loadRandomAyah() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Text(ayah.arabic1)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.white)
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            if !ayah.transliteration.isEmpty {
                Text(ayah.transliteration)
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Result Content

    private func resultContent(passed: Bool, score: Int) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill((passed ? Color(hex: "#4ADE80") : Color.red).opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: passed ? "checkmark" : "xmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(passed ? Color(hex: "#4ADE80") : .red)
            }
            .padding(.bottom, 24)

            Text(passed ? "Masha'Allah! ✨" : "Keep trying")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 8)

            Text(
                passed
                    ? "App unblocked for \(viewModel.unblockDurationMinutes) minutes"
                    : "Recite again more carefully"
            )
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.55))
            .padding(.bottom, 32)

            VStack(spacing: 8) {
                HStack {
                    Text("Similarity")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text("\(score)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(passed ? Color(hex: "#4ADE80") : .red)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1)).frame(height: 6)
                        Capsule()
                            .fill(passed ? Color(hex: "#4ADE80") : Color.red)
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                            .animation(.spring(duration: 0.8), value: score)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

        }
    }

    // MARK: - Bottom Action Area

    @ViewBuilder
    private var bottomActionArea: some View {
        switch viewModel.state {
        case .ready:
            micButton(isRecording: false) { viewModel.startRecording() }

        case .recording:
            VStack(spacing: 12) {
                Text("Speak into the phone now")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                micButton(isRecording: true) { viewModel.stopRecordingAndTranscribe() }
            }

        case .transcribing:
            micButton(isRecording: false, disabled: true) {}

        case .result(let passed, _):
            if passed {
                primaryButton(title: "Open App", action: { dismiss() })
            } else {
                VStack(spacing: 12) {
                    primaryButton(title: "Try Again", action: { viewModel.retry() })
                    Button { dismiss() } label: {
                        Text("Maybe Later")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Mic Button

    private func micButton(
        isRecording: Bool,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(.white.opacity(0.07))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
                Circle()
                    .fill(disabled ? Color.white.opacity(0.2) : Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 6)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(disabled ? .white.opacity(0.3) : Color(hex: "#0B2016"))
            }
        }
        .disabled(disabled)
    }

    // MARK: - Primary Button

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#0B2016"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(hex: "#4ADE80"))
                )
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview
#Preview {
    ReciteToUnblockView()
        .environmentObject(Router())
        .environmentObject(ReciteToUnblockViewModel())
}
