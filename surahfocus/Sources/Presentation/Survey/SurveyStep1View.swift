//
//  SurveyStep2View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct SurveyStep1View: View {

    @ObservedObject var viewModel: SurveyViewModel

    private let options: [(value: String, title: String)] = [
        ("almostNever", "😖 Almost Never"),
        ("sometimes", "😟 Sometimes"),
        ("prettyOften", "🤲 Pretty often"),
        ("everyTime", "🙌 Every time I try")
    ]

    var body: some View {
        VStack(alignment: .leading) {

            Spacer()

            // MARK: - Title
            Text("How often does your phone distract you from your Quran recitation?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)


            // MARK: - Subtitle
            Text("Select all that apply")
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
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Option View
    private func surveyOption(value: String, title: String) -> some View {

        let isSelected = viewModel.answers.phoneFrequency == value

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
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.answers.phoneFrequency = value
            }
        }
    }
}
