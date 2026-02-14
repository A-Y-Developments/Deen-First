import SwiftUI
import FamilyControls

struct FocusSectionView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: FocusSectionViewModel

    init(router: Router) {
        _viewModel = StateObject(wrappedValue: FocusSectionViewModel(router: router))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            blockedAppsSection
                            selectedSurahsSection
                            addSurahButton
                            startSessionButton
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Focus Session")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.appSelection
        )
        .onChange(of: viewModel.appSelection) { oldValue, newValue in
            viewModel.updateAppSelection(newValue)
        }
        .task {
            await viewModel.loadData()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apps to Block")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.openAppPicker() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }

            VStack(spacing: 8) {
                if viewModel.selectedAppsCount == 0 {
                    Text("No apps selected")
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    HStack {
                        Text("\(viewModel.selectedAppsCount) app\(viewModel.selectedAppsCount == 1 ? "" : "s") selected")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var selectedSurahsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Surahs")
                .font(.headline)
                .foregroundColor(.white)

            if viewModel.selectedSurahs.isEmpty {
                Text("No surahs selected")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.selectedSurahs) { surahWithRange in
                    Button(action: { viewModel.navigateToAyahRange(surahWithRange) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(surahWithRange.surah.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                Text("Ayah \(surahWithRange.startAyah) - \(surahWithRange.endAyah)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var addSurahButton: some View {
        Button(action: { viewModel.navigateToSelectSurah() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Surah")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var startSessionButton: some View {
        Button(action: {
            Task {
                await viewModel.navigateToDownload()
            }
        }) {
            Text("Start Session")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canStartSession ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!viewModel.canStartSession)
    }
}

#Preview {
    NavigationStack {
        FocusSectionView(router: Router())
    }
}
