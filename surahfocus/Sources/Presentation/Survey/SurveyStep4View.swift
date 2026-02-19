//
//  SurveyStep4View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct SurveyStep4View: View {

    @ObservedObject var viewModel: SurveyViewModel

    private let options: [(value: String, title: String)] = [
        ("veryMuch", "1-2 hours"),
        ("prettyMuch", "2-4 hours"),
        ("little", "4-6 hours"),
        ("notAtAll", "6-8 hours")
    ]

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: - Title
            Text("How long do you use social media app?")
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

                ForEach(options, id: \.value) { option in
                    surveyOption(
                        value: option.value,
                        title: option.title
                    )
                }
            }
            .padding(.top, 48)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Option View
    private func surveyOption(value: String, title: String) -> some View {

        let isSelected = viewModel.answers.lifeImpact == value

        return HStack {
            Text(title)
                .foregroundColor(isSelected ? Color.secondary200 : Color.gray4)
                .font(.system(.callout, weight: .medium))

            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.callout, weight: .medium))
                .foregroundColor(isSelected ? Color.secondary300.opacity(0.4) : Color.clear)
        }
        .padding()
        .background(
            isSelected ? Color.primary600 : Color.primary500.opacity(0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.secondary300.opacity(0.4) : Color.clear,
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.answers.lifeImpact = value
            }
        }
    }
}
