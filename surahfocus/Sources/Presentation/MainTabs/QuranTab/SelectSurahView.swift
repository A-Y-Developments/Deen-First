import SwiftUI

struct SelectSurahView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SelectSurahViewModel

    init(existingSurahs: [SurahWithRange] = []) {
        _viewModel = StateObject(wrappedValue: SelectSurahViewModel(existingSurahs: existingSurahs))
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
                searchBar

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    surahList
                }
            }
        }
        .navigationTitle("Select Surahs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Continue") {
                    handleContinue()
                }
                .disabled(viewModel.selectedCount == 0)
            }
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            viewModel.applySearch()
        }
    }

    private func handleContinue() {
        // Save to UserDefaults
        UserDefaults.standard.set(Array(viewModel.selectedSurahNumbers), forKey: "lastSelectedSurahs")
        // Dismiss the view
        dismiss()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField("Search surahs...", text: $viewModel.searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    private var surahList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredSurahs) { surah in
                    SurahSelectionRow(
                        surah: surah,
                        isSelected: viewModel.isSelected(surah)
                    ) {
                        viewModel.toggleSelection(surah)
                    }
                }
            }
            .padding()
        }
    }
}

struct SurahSelectionRow: View {
    let surah: Surah
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(surah.number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(isSelected ? Color.blue : Color.white.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(surah.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text(surah.englishName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SelectSurahView()
    }
}
