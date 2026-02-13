//
//  SurveyStep4View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct SurveyStep4View: View {
    @State private var selectedOptions: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            // MARK: - Title
            Text("Does inconsistent recitation impact your everyday life?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            
            // MARK: - Subtitle
            Text("Be honest with yourself.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#8E8E93"))
                .padding(.top, 12)
            
            
            // MARK: - Options
            VStack(spacing: 16) {
                
                surveyOption(
                    index: 0,
                    title: "😔 Very Much"
                )
                
                surveyOption(
                    index: 1,
                    title: "😶 Pretty Much"
                )
                
                surveyOption(
                    index: 2,
                    title: "😐 Yes, a little"
                )
                
                surveyOption(
                    index: 3,
                    title: "😌 Not at all"
                )
                // Tambahkan option lain nanti di sini
            }
            .padding(.top, 48)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Option View
    private func surveyOption(index: Int, title: String) -> some View {
        
        let isSelected = selectedOptions.contains(index)
        
        return HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(
            Color(hex: "#102D30")
                .opacity(isSelected ? 1 : 0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.white : Color.clear,
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            if isSelected {
                selectedOptions.remove(index)
            } else {
                selectedOptions.insert(index)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOptions)
    }
}
