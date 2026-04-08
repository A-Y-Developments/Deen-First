import SwiftUI
import FamilyControls

struct FocusSectionView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: FocusSectionViewModel

    let unlockRuleId: UUID?

    init(unlockRuleId: UUID? = nil) {
        self.unlockRuleId = unlockRuleId
    }

    var body: some View {
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
                                    Text(viewModel.appsCountText)
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
                                    router.navigate(to: .selectSurah(surahs: viewModel.selectedSurahs))
                                }
                            }
                            .padding(.top)
                            
                            Spacer()
                            
                            // MARK: Start Session Button
                            Button {
                                Task {
                                    do {
                                        let (surahs, ayahs) = try await viewModel.prepareForSession()
                                        router.navigate(to: .activeSession(
                                            surahs: surahs,
                                            ayahs: ayahs,
                                            isUnblockSession: unlockRuleId != nil,
                                            unlockRuleId: unlockRuleId
                                        ))
                                    } catch {
                                        viewModel.errorMessage = error.localizedDescription
                                    }
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
                    }
                    .padding(.top, 48)
                }
            }
        }
        .secondaryBackground()
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
}

#Preview {
    NavigationStack {
        FocusSectionView()
            .environmentObject(FocusSectionViewModel())
            .environmentObject(Router())
    }
}
