import SwiftUI

struct SelectSurahView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SelectSurahViewModel
    @State private var showSearch = false

    let existingSurahs: [SurahWithRange]

    init(existingSurahs: [SurahWithRange] = []) {
        self.existingSurahs = existingSurahs
    }

    var body: some View {
        VStack(spacing: 0) {
            if showSearch {
                searchBar
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else {
                surahList
            }
        }
        .navigationTitle("Select Surahs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        showSearch.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                handleContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            .background(Color.primary900)
        }
        .secondaryBackground()
        .task {
            viewModel.configure(existingSurahs: existingSurahs)
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
                .foregroundColor(.white.opacity(0.6))

            TextField("Search surahs...", text: $viewModel.searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color.primary500.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
    }

    private var surahList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
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
            HStack(spacing: 16) {

                // Number Circle
                Text("\(surah.number)")
                    .font(.system(.callout, design: .serif))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.primary500.opacity(0.4))
                    .clipShape(Circle())

                // Surah Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(surah.name)
                        .font(.system(.body))
                        .foregroundColor(.white)

                    Text(surah.englishName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Select Indicator
                ZStack {
                    Circle()
                        .stroke(Color.primary400, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.primary400)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(Color.primary500.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SelectSurahView()
            .environmentObject(SelectSurahViewModel())
    }
}
