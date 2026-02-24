//
//  CalculateSurveyView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct CalculateSurveyView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: SummaryViewModel
    let answers: SurveyAnswers

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                    Text("\(viewModel.percentage)%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color.secondary200)

                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray4.opacity(0.2))
                            .frame(height: 5)
                            .clipShape(Capsule())

                        Rectangle()
                            .fill(Color.secondary200)
                            .frame(width: viewModel.progress, height: 5)
                            .clipShape(Capsule())
                    }
                    .frame(height: 2)

                    Text("Calculating\(String(repeating: ".", count: viewModel.ellipsisCount))")
                        .font(.callout)
                        .foregroundColor(Color.white)

                    Spacer() 

                    ZStack {
                        // Wave ripple circles - expand outward and fade
                        ForEach(0..<2) { i in
                            Circle()
                                .stroke(Color(hex: "#ADA666"), lineWidth: 1.5)
                                .frame(width: 90, height: 90)
                                .scaleEffect(isAnimating ? 2.5 : 1.0)
                                .opacity(isAnimating ? 0 : 0.4)
                                .animation(
                                    .easeOut(duration: 2)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 1.0),
                                    value: isAnimating
                                )
                        }

                        Image("mosque")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .onAppear { isAnimating = true }
                    .padding(.top, 56)
                    .padding(.bottom, 48)

                    Spacer()

                    Text("COMMUNITY INSIGHT")
                        .font(.callout)
                        .foregroundStyle(Color.secondary400)

                    Text("A lot of users have chosen Deen First for Ramadan prep.")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(16)

                    Spacer()
            }
            .padding(.horizontal, 72)
            .padding(.top, 100)
            .mainBackground()
            .onAppear {
                viewModel.startCalculation(screenWidth: geometry.size.width) {
                    viewModel.answers = answers
                    router.navigate(to: .summary(step: 1, answers: answers))
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }


}

#Preview {
    CalculateSurveyView(answers: SurveyAnswers())
        .environmentObject(Router())
        .environmentObject(SummaryViewModel())
}
