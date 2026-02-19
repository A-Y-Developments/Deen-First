//
//  CalculateSurveyView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct CalculateSurveyView: View {

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = SummaryViewModel()
    let answers: SurveyAnswers

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

                    ZStack {
                        Circle()
                            .stroke(Color(hex: "#ADA666").opacity(0.2), lineWidth: 2)
                            .frame(width: 220, height: 220)

                        Circle()
                            .stroke(Color(hex: "#ADA666").opacity(0.2), lineWidth: 2)
                            .frame(width: 170, height: 170)

                        Image("mosque")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 48)

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
            .background {
                Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
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
}
