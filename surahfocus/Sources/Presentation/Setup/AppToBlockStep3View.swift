//
//  AppToBlockStep1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlockStep3View: View {
    @EnvironmentObject private var viewModel: SetupViewModel

    private let prayerOrder = ["subuh", "zuhr", "asr", "maghrib", "isya"]

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
                ForEach(prayerOrder, id: \.self) { prayer in
                    prayerOption(prayer: prayer)
                }
            }
            .padding(.top, 32)

            Spacer()
        }
    }

    // MARK: - Prayer Option Component
    private func prayerOption(prayer: String) -> some View {
        let isSelected = viewModel.isSelected(prayer)

        return Button {
            viewModel.togglePrayer(prayer)
        } label: {
            HStack {
                Text(getPrayerTitle(prayer))
                    .foregroundColor(isSelected ? Color.secondary200 : .white)
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
                    .stroke(isSelected ? Color.secondary300.opacity(0.4) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func getPrayerTitle(_ prayer: String) -> String {
        switch prayer {
        case "subuh": return "Fajr (4.30 AM - 6.00 AM)"
        case "zuhr": return "Dhuhr (12.15 PM - 1.30 PM)"
        case "asr": return "Asr (3.45 PM - 5.00 PM)"
        case "maghrib": return "Maghrib (6.15 PM - 7.15 PM)"
        case "isya": return "Isha (7.30 PM - 8.45 PM)"
        default: return prayer
        }
    }
}
