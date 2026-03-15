//
//  AppToBlockStep1View.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlockStep2View: View {
    @EnvironmentObject private var viewModel: SetupViewModel

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
                .fixedSize(horizontal: false, vertical: true)

            // MARK: - Subtitle
            Text("Let’s pick one")
                .font(.callout)
                .foregroundColor(Color.gray4)
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Time Options
            VStack(spacing: 16) {
                timeOption(limit: .fifteenMin)
                timeOption(limit: .thirtyMin)
                timeOption(limit: .oneHour)
                timeOption(limit: .twoHours)
            }
            .padding(.top, 32)

            Spacer()
        }
    }

    // MARK: - Time Option Component
    private func timeOption(limit: TimeLimit) -> some View {
        let isSelected = viewModel.selectedDailyLimit == limit

        return Button {
            viewModel.selectLimit(limit)
        } label: {
            HStack {
                Text(limit.displayName)
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
                    .stroke(
                        isSelected ? Color.secondary300.opacity(0.4) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
