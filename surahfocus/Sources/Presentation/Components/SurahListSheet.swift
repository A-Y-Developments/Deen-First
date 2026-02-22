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
        ZStack {
            VStack(spacing: 16) {
                SearchBar(text: $viewModel.searchQuery,
                          placeholder: "Search surahs...")
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if viewModel.isLoading && viewModel.surahs.isEmpty {
                    ProgressView()
                        .padding(.top, 40)
                } else if !viewModel.searchQuery.isEmpty &&
                            viewModel.filteredSurahs.isEmpty {
                    
                    // MARK: - Empty Search State
                    VStack(spacing: 12) {
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(Color.secondary300.opacity(0.6))
                        
                        Text("No Result for \"\(viewModel.searchQuery)\"")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Check the spelling or try a new search.")
                            .font(.footnote)
                            .foregroundColor(Color.gray4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                } else {
                    LazyVStack(spacing: 12) {
                        if viewModel.viewMode == .surah {
                            ForEach(viewModel.filteredSurahs) { surah in
                                SurahCard(surah: surah) {
                                    router.navigate(to: .quranReading(surahId: surah.number))
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
                                        router.navigate(to: .quranReading(surahId: surah.number))
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
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}
