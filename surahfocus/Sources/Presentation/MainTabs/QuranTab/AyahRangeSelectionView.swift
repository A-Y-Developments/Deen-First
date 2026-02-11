import SwiftUI

struct AyahRangeSelectionView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel: AyahRangeSelectionViewModel

    init(surah: Surah) {
        _viewModel = StateObject(wrappedValue: AyahRangeSelectionViewModel(surah: surah))
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

                VStack(spacing: 8) {
                    Text(viewModel.surah.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\(viewModel.surah.numberOfAyahs) verses")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Ayah")
                            .font(.headline)
                            .foregroundColor(.white)

                        Picker("Start", selection: $viewModel.startAyah) {
                            ForEach(1...viewModel.surah.numberOfAyahs, id: \.self) { ayah in
                                Text("\(ayah)").tag(ayah)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .clipped()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Ayah")
                            .font(.headline)
                            .foregroundColor(.white)

                        Picker("End", selection: $viewModel.endAyah) {
                            ForEach(viewModel.startAyah...viewModel.surah.numberOfAyahs, id: \.self) { ayah in
                                Text("\(ayah)").tag(ayah)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .clipped()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }

                if viewModel.isValid {
                    Text("Selected: Ayah \(viewModel.startAyah) - \(viewModel.endAyah) (\(viewModel.endAyah - viewModel.startAyah + 1) verses)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.deleteRange()
                        router.navigateBack()
                    }) {
                        Text("Delete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.saveRange()
                        router.navigateBack()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Select Ayah Range")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AyahRangeSelectionView(surah: Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Meccan"))
    }
}
