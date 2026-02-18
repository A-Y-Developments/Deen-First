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
                .foregroundColor(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            
            // MARK: - Title
            Text("How much time do you need for these apps each day?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            
            // MARK: - Subtitle
            Text("Let’s pick one")
                .font(.callout)
                .foregroundColor(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // MARK: - Time Options
            VStack(spacing: 16) {
                timeOption(title: "15 minutes")
                timeOption(title: "30 minutes")
                timeOption(title: "1 hour")
                timeOption(title: "2 hours")
            }
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
                        ? Color.secondary200
                        : .white
                    )
                    .font(.body)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.callout, weight: .medium))
                        .foregroundColor(Color.secondary300.opacity(0.4))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.primary600 : Color.primary500.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                        ? Color.secondary300.opacity(0.4)
                        : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
