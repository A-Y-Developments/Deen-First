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
            // MARK: - Title
            Text("How often does your phone distract you from your Quran recitation?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)


            // MARK: - Subtitle
            Text("Select all that apply")
                .font(.subheadline)
                .foregroundColor(Color.gray4)
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
            .padding(.top, 40)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Option View
    private func surveyOption(value: String, title: String) -> some View {

        let isSelected = viewModel.answers.phoneFrequency == value

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
                viewModel.setPhoneFrequency(value)
            }
        }
    }
}
