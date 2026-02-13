//
//  QuranReadingView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct QuranReadingView: View {
    
    let surahs = [
        "Al-An'am",
        "Al-Ma'idah",
        "An-Nisa",
        "Ali Imraan",
        "Al-Baqara",
        "Al-Faatiha"
    ]
    
    @State private var selectedSurah: String = "Al-Faatiha"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: Horizontal Surah Scroll
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(surahs, id: \.self) { surah in
                                VStack(spacing: 6) {
                                    Text(surah)
                                        .font(.system(.callout, design: .serif))
                                        .foregroundColor(
                                            selectedSurah == surah
                                            ? Color(hex: "ADA666")
                                            : .white.opacity(0.6)
                                        )
                                        .padding(.bottom, 8)
                                    
                                    Rectangle()
                                        .fill(Color(hex: "ADA666"))
                                        .frame(height: 2)
                                        .opacity(selectedSurah == surah ? 1 : 0)
                                }
                                .animation(.easeInOut(duration: 0.2), value: selectedSurah)
                                .onTapGesture {
                                    selectedSurah = surah
                                }
                                .id(surah)
                            }

                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .onAppear {
                        if let last = surahs.last {
                            proxy.scrollTo(last, anchor: .trailing)
                        }
                    }
                }
                
                
                // MARK: Surah Info Header
                HStack {
                    Text("1. \(selectedSurah)")
                        .font(.system(.callout, design: .serif))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("7 Ayah, Makkiyah")
                        .font(.callout)
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding()
                .background(Color(hex: "ADA666"))
                
                
                // MARK: Ayah Content
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(1...7, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 12) {
                                
                                Text("1:\(index)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "8E8E93"))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                
                                Text("بِسْمِ ٱللَّٰهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                                    .font(.system(size: 24, design: .serif))
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.white)
                                
                                Text("Bismillah hir rahman nir raheem")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                
                                Text("In the Name of Allah—the Most Compassionate, Most Merciful")
                                    .font(.footnote)
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                index % 2 == 0
                                ? Color(hex: "0e3034")
                                : Color(hex: "062023")
                            )
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        print("More tapped")
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        print("Search tapped")
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color(hex: "062629"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color(hex: "062629").ignoresSafeArea())
        }
    }
}

#Preview {
    QuranReadingView()
}
