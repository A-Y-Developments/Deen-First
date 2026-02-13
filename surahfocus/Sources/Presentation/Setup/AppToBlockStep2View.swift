//
//  AppToBlockStep1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlockStep2View: View {
    
    @State private var selectedTime: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            // MARK: - Small Intro
            Text("Let's set boundaries!")
                .font(.callout)
                .foregroundColor(Color(hex: "#AEAEB2"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            
            // MARK: - Title
            Text("How much time do you need for these apps each day?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            
            // MARK: - Subtitle
            Text("Let’s pick one")
                .font(.callout)
                .foregroundColor(Color(hex: "#8E8E93"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            
            // MARK: - Time Options
            VStack(spacing: 16) {
                timeOption(title: "15 minutes")
                timeOption(title: "30 minutes")
                timeOption(title: "1 hour")
                timeOption(title: "2 hours")
            }
            .padding(.horizontal)
            .padding(.top, 32)
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTime)
    }
    
    
    // MARK: - Time Option Component
    private func timeOption(title: String) -> some View {
        
        let isSelected = selectedTime == title
        
        return Button {
            selectedTime = title
        } label: {
            HStack {
                
                Text(title)
                    .foregroundColor(
                        isSelected
                        ? Color(hex: "#DBDABD")
                        : .white
                    )
                    .font(.body)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: "#DBDABD"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#102D30").opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                        ? Color(hex: "#DBDABD").opacity(0.4)
                        : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
