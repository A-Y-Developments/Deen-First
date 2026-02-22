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
            // Background
            Image("secondary-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 24) {
                                
                                // MARK: Blocked App
                                VStack(alignment: .leading) {
                                    Text("Blocked App")
                                        .font(.system(.callout, weight: .medium))
                                        .foregroundColor(Color.secondary400)
                                    
                                    HStack {
                                        Text("\(viewModel.selectedAppsCount) app\(viewModel.selectedAppsCount == 1 ? "" : "s") selected")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                    .background(Color.primary500.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture {
                                        viewModel.openAppPicker()
                                    }                                }
                                
                                // MARK: Surah to Listen
                                VStack(alignment: .leading) {
                                    Text("Surah to Listen")
                                        .font(.system(.callout, weight: .medium))
                                        .foregroundColor(Color.secondary400)
                                    
                                    ForEach(viewModel.selectedSurahs) { surahWithRange in
                                        
                                        VStack(alignment: .leading, spacing: 16) {
                                            
                                            // Surah Header
                                            HStack {
                                                Text(surahWithRange.surah.name)
                                                    .font(.system(.title3))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Button {
                                                    viewModel.deleteSurah(surah: surahWithRange.surah)
                                                    Task {
                                                        await viewModel.loadData()
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white.opacity(0.7))
                                                        .font(.title3)
                                                }
                                            }
                                            
                                            
                                            // Ayah Range
                                            HStack(spacing: 32) {
                                                Text("Ayah \(surahWithRange.startAyah) - \(surahWithRange.endAyah)")
                                                    .foregroundColor(.white)
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                            .font(.system(.body))
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(Color.primary500.opacity(0.4))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                        .padding(20)
                                        .background(Color.primary500.opacity(0.3)).ignoresSafeArea()
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .onTapGesture {
                                            viewModel.openRangeSheet(for: surahWithRange)
                                        }
                                        
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.white)
                                        Text("Add Surah")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.primary500.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture {
                                        viewModel.navigateToSelectSurah()
                                    }
                                }
                                .padding(.top)
                                
                                Spacer()
                                
                                // MARK: Start Session Button
                                Button {
                                    Task {
                                        await viewModel.navigateToDownload()
                                    }
                                } label: {
                                    Text("Start Session")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(viewModel.canStartSession ? .white : .gray)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                                // glow effect
                                .shadow(
                                    color: viewModel.canStartSession ? Color.primary400 :  Color.primary400.opacity(0),
                                    radius: 12
                                )
                                .disabled(!viewModel.canStartSession)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 40)
//                            blockedAppsSection
//                            selectedSurahsSection
//                            addSurahButton
//                            startSessionButton
                        }
                        .padding(.top, 48)
                    }
                }
            }
        }
        .navigationTitle("Focus Session")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(item: $viewModel.editingSurah) { surahWithRange in
            AyahRangeSheetView(
                surah: surahWithRange.surah,
                startAyah: surahWithRange.startAyah,
                endAyah: surahWithRange.endAyah
            ) { newStart, newEnd in
                viewModel.updateSurahRange(
                    SurahWithRange(
                        surah: surahWithRange.surah,
                        startAyah: newStart,
                        endAyah: newEnd
                    )
                )
            }
            .presentationDetents([.fraction(0.5)])
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
