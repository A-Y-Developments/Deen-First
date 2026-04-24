import SwiftUI

struct AyahPoolView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: AyahPoolViewModel

    init(viewModel: AyahPoolViewModel = MainActor.assumeIsolated { AyahPoolViewModel() }) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.primary900
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                addButton
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                contentView
            }
        }
        .navigationTitle("My Ayah Pool")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .alert("Pool is full", isPresented: $viewModel.showPoolFullAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached the 20 ayah limit. Remove an ayah to add a new one.")
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.countLabel) ayahs selected")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var addButton: some View {
        Button(action: addTapped) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Ayahs")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            Spacer()
        } else if viewModel.isEmpty {
            emptyStateView
        } else {
            listView
                .overlay(alignment: .top) {
                    if viewModel.isRemoving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(.top, 8)
                    }
                }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            Text("Your pool is empty. Recite to Unblock will use random ayahs.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var listView: some View {
        List {
            ForEach(viewModel.items, id: \.id) { item in
                AyahPoolRow(
                    title: viewModel.displayLabel(for: item),
                    arabicText: item.arabicText
                )
                .listRowBackground(Color.white.opacity(0.04))
                .listRowSeparatorTint(Color.white.opacity(0.08))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.remove(id: item.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.primary900)
    }

    // MARK: - Actions

    private func addTapped() {
        guard viewModel.handleAddAyahsTap() else { return }
        router.navigate(to: .ayahPoolSurahPicker)
    }
}

// MARK: - Row

private struct AyahPoolRow: View {
    let title: String
    let arabicText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(arabicText)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.vertical, 6)
    }
}
