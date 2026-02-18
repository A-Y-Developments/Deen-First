//
//  SelectSurahView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SelectSurahFocusView: View {
    
    @State private var searchText: String = ""
    @State private var selectedSurah: Int? = nil
    
    let surahs = [
        (1, "Al-Faatiha", "The Opener"),
        (2, "Al-Baqara", "The Cow"),
        (3, "Ali Imraan", "Family of Imran"),
        (4, "An-Nisa", "The Women"),
        (5, "Al-Ma'idah", "The Table Spread"),
        (6, "Al-An'am", "The Cattle")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    ForEach(surahs, id: \.0) { surah in
                        HStack(spacing: 16) {
                            
                            // Number Circle
                            Text("\(surah.0)")
                                .font(.system(.callout, design: .serif))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.primary500.opacity(0.4))
                                .clipShape(Circle())
                            
                            // Surah Name
                            VStack(alignment: .leading, spacing: 4) {
                                Text(surah.1)
                                    .font(.system(.body))
                                    .foregroundColor(.white)
                                
                                Text(surah.2)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            
                            Spacer()
                            
                            // Select Indicator
                            ZStack {
                                Circle()
                                    .stroke(Color.primary400, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                
                                if selectedSurah == surah.0 {
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
                        .onTapGesture {
                            selectedSurah = surah.0
                        }
                    }
                }
                .padding()
            }
            .background(Color(hex: "041315").ignoresSafeArea())
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
            
            // Sticky Bottom Button
            .safeAreaInset(edge: .bottom) {
                Button {
                    print("Continue tapped")
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
        }
    }
}

#Preview {
    SelectSurahFocusView()
}
