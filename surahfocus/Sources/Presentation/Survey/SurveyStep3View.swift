//
//  SurveyStep3View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct SurveyStep3View: View {
    
    @State private var selectedOptions: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            // MARK: - Title
            Text("Which apps usually interrupt your connection with Allah?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            
            // MARK: - Subtitle
            Text("Select all that apply.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#8E8E93"))
                .padding(.top, 12)
            
            
            // MARK: - Options
            VStack(spacing: 16) {
                
                surveyOption(
                    index: 0,
                    title: "📱 Social Media"
                )
                
                surveyOption(
                    index: 1,
                    title: "📺 Video/Streaming"
                )
                
                surveyOption(
                    index: 2,
                    title: "🎮 Games"
                )
                
                surveyOption(
                    index: 3,
                    title: "💬 Messaging"
                )
                
                surveyOption(
                    index: 4,
                    title: "📰 News"
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
