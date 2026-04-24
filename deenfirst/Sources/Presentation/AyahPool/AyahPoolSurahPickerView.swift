import SwiftUI

struct AyahPoolSurahPickerView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: AyahPoolSurahPickerViewModel
    @State private var showSearch = false

    init(viewModel: AyahPoolSurahPickerViewModel = MainActor.assumeIsolated { AyahPoolSurahPickerViewModel() }) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.primary900.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.selectedSurah == nil {
                    surahListContent
                } else {
                    ayahListContent
                }
            }
        }
        .navigationTitle(viewModel.selectedSurah == nil ? "Add Ayahs" : "Select Ayahs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.selectedSurah == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { showSearch.toggle() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear { viewModel.loadInitial() }
        .onChange(of: viewModel.searchText) { _, _ in viewModel.applySearch() }
        .onChange(of: viewModel.didFinishAdding) { _, finished in
            if finished { router.navigateBack() }
        }
        .alert("Pool is full", isPresented: $viewModel.showPoolFullAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached the 20 ayah limit. Remove an ayah to add a new one.")
        }
        .alert(
            addSummaryAlertTitle,
            isPresented: Binding(
                get: { viewModel.addSummary != nil },
                set: { if !$0 { viewModel.acknowledgeAddSummary() } }
            )
        ) {
            Button("OK") { viewModel.acknowledgeAddSummary() }
        } message: {
            Text(viewModel.addSummary?.message ?? "")
        }
    }

    private var addSummaryAlertTitle: String {
        guard let summary = viewModel.addSummary else { return "" }
        if summary.added == 0 { return "No ayahs added" }
        if summary.added < summary.requested { return "Partial add" }
        return "Added"
    }

    // MARK: - Surah list

    @ViewBuilder
    private var surahListContent: some View {
        if showSearch {
            searchBar
        }

        if viewModel.isLoadingSurahs && viewModel.allSurahs.isEmpty {
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSurahs) { surah in
                        Button {
                            viewModel.selectSurah(surah)
                        } label: {
                            SurahPickerRow(surah: surah)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
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

    // MARK: - Ayah list

    @ViewBuilder
    private var ayahListContent: some View {
        HStack {
            Button {
                viewModel.backToSurahList()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Surahs")
                }
                .foregroundColor(.white.opacity(0.8))
                .font(.subheadline)
            }
            Spacer()
            if let surah = viewModel.selectedSurah {
                Text(surah.englishName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()
            Text(viewModel.selectedCountLabel)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

        if viewModel.isLoadingAyahs && viewModel.ayahs.isEmpty {
            Spacer()
            ProgressView().tint(.white)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.ayahs) { ayah in
                        AyahCheckboxRow(
                            ayah: ayah,
                            isPooled: viewModel.isPooled(ayah),
                            isSelected: viewModel.isSelected(ayah)
                        ) {
                            viewModel.toggleSelection(ayah)
                        }
                    }
                }
                .padding()
            }
            addSelectedButton
        }
    }

    private var addSelectedButton: some View {
        Button {
            viewModel.addSelected()
        } label: {
            Text(viewModel.newlySelected.isEmpty ? "Add Selected" : "Add \(viewModel.newlySelected.count) Selected")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.newlySelected.isEmpty ? Color.white.opacity(0.4) : Color.white)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.vertical, 12)
        }
        .disabled(viewModel.newlySelected.isEmpty)
        .background(Color.primary900)
    }
}

// MARK: - Rows

private struct SurahPickerRow: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 16) {
            Text("\(surah.number)")
                .font(.system(.callout, design: .serif))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.primary500.opacity(0.4))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(surah.englishName)
                    .font(.body)
                    .foregroundColor(.white)
                Text("\(surah.numberOfAyahs) ayahs")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(Color.primary500.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AyahCheckboxRow: View {
    let ayah: Ayah
    let isPooled: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                checkbox
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Ayah \(ayah.numberInSurah)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                    Text(ayah.text)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(isPooled ? 0.5 : 0.9))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }
            }
            .padding()
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isPooled)
    }

    private var checkbox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary400, lineWidth: 2)
                .frame(width: 24, height: 24)
            if isPooled || isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPooled ? Color.primary400.opacity(0.6) : Color.primary400)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AyahPoolSurahPickerView()
            .environmentObject(Router())
    }
}
