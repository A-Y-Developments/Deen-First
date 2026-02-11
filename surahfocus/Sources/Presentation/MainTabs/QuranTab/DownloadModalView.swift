import SwiftUI

struct DownloadModalView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: DownloadModalViewModel

    init(surahs: [SurahWithRange]) {
        _viewModel = StateObject(wrappedValue: DownloadModalViewModel(surahs: surahs))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                if viewModel.isDownloading {
                    downloadingView
                } else if viewModel.downloadComplete {
                    completeView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled(!viewModel.canDismiss)
        .onAppear {
            viewModel.setRouter(router)
        }
        .task {
            await viewModel.startDownload()
        }
    }

    private var downloadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.overallProgress)

                VStack(spacing: 4) {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Downloading ayah audio...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            VStack(spacing: 8) {
                Text("\(viewModel.downloadedCount) / \(viewModel.totalAyahCount) ayahs downloaded")
                    .font(.headline)
                    .foregroundColor(.white)

                ProgressView(value: viewModel.overallProgress)
                    .tint(.blue)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }

    private var completeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Download Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Download Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Button("Retry") {
                viewModel.retry()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        DownloadModalView(surahs: [
            SurahWithRange(surah: Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Meccan"), startAyah: 1, endAyah: 7)
        ])
    }
}
