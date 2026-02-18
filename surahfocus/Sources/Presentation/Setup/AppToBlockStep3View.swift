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
                .foregroundColor(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // MARK: - Title
            Text("Set your prayer times to stay focused and connected")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            // MARK: - Subtitle
            Text("You can select more than one")
                .font(.callout)
                .foregroundColor(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // MARK: - Prayer Options
            VStack(spacing: 16) {
                prayerOption("Fajr (4.30 AM - 6.00 AM)")
                prayerOption("Dhuhr (12.15 PM - 1.30 PM)")
                prayerOption("Asr (3.45 PM - 5.00 PM)")
                prayerOption("Maghrib (6.15 PM - 7.15 PM)")
                prayerOption("Isha (7.30 PM - 8.45 PM)")
            }
            .padding(.top, 32)
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPrayers)
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
                    .fill(
                        isSelected
                        ? Color.primary600
                        : Color.primary500.opacity(0.4)
                    )
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
