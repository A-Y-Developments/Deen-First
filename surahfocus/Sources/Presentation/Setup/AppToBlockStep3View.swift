//
//  AppToBlockStep1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlockStep3View: View {
    
    @State private var selectedPrayers: Set<String> = []
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            // MARK: - Small Intro
            Text("Let's set boundaries!")
                .font(.callout)
                .foregroundColor(Color(hex: "#AEAEB2"))
            
            
            // MARK: - Title
            Text("Set your prayer times to stay focused and connected")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            
            // MARK: - Prayer Options
            VStack(spacing: 16) {
                prayerOption("Fajr (4.30 AM - 6.00 AM)")
                prayerOption("Dhuhr (12.15 PM - 1.30 PM)")
                prayerOption("Asr (3.45 PM - 5.00 PM)")
                prayerOption("Maghrib (6.15 PM - 7.15 PM)")
                prayerOption("Isha (7.30 PM - 8.45 PM)")
            }
            .padding(.horizontal)
            .padding(.top, 40)
            
            Spacer()
        }
    }
    
    
    // MARK: - Prayer Option Component
    private func prayerOption(_ title: String) -> some View {
        let isSelected = selectedPrayers.contains(title)
        
        return Button {
            if isSelected {
                selectedPrayers.remove(title)
            } else {
                selectedPrayers.insert(title)
            }
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
                    .fill(Color(hex: "#102D30"))
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
