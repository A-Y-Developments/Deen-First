//
//  SurahListSheet.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct SurahListSheet: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                SearchBar(text: $viewModel.searchQuery,
                          placeholder: "Search surahs...")
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                HStack {
                    Spacer()
                    Menu {
                        Button {
                            viewModel.viewMode = .juz
                        } label: {
                            Label("Juz View", systemImage: viewModel.viewMode == .juz ? "checkmark" : "")
                        }
                        Button {
                            viewModel.viewMode = .surah
                        } label: {
                            Label("Surah View", systemImage: viewModel.viewMode == .surah ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                
                if viewModel.isLoading && viewModel.surahs.isEmpty {
                    ProgressView()
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.viewMode == .surah {
                                ForEach(viewModel.filteredSurahs) { surah in
                                    SurahCard(surah: surah) {
                                        router.navigate(to: .surahDetail(surahId: surah.number))
                                    }
                                }
                            } else {
                                // render juz view
                                VStack(alignment: .leading) {
                                    Text("Juz 1")
                                        .font(.system(.body))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: "ADA666"))
                                    ForEach(viewModel.filteredSurahs) { surah in
                                        SurahCard(surah: surah) {
                                            router.navigate(to: .surahDetail(surahId: surah.number))
                                        }
                                    }
                                }
                            }
                            
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
            }
            .background(Color(hex: "051b1d"))
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}
