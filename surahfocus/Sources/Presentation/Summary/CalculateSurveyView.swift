//
//  CalculateSurveyView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct CalculateSurveyView: View {

    @EnvironmentObject var router: Router
    let answers: SurveyAnswers

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "062629"),
                    Color(hex: "041315")
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            VStack(spacing: 24) {

                // MARK: - Header
                Text("COMMUNITY INSIGHT")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("A lot of users have chosen Surah Focus for Ramadan prep.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .multilineTextAlignment(.leading)


                // MARK: - Mosque with Double Circle
                ZStack {

                    // Outer Circle (Stroke Only)
                    Circle()
                        .stroke(
                            Color(hex: "#ADA666").opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 220, height: 220)

                    // Inner Circle (Stroke Only)
                    Circle()
                        .stroke(
                            Color(hex: "#ADA666").opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 170, height: 170)

                    // Image
                    Image("mosque")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                }
                .padding(.top, 32)
                .padding(.bottom, 48)



                // MARK: - Percentage
                Text("19%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#DBDABD"))


                // MARK: - Footer Text
                Text("Calculating time saved...")
                    .foregroundColor(Color(hex: "#ADA666"))


                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                router.replaceWith(.summary(step: 1, answers: answers))
            }
        }
    }
}

#Preview {
    CalculateSurveyView(answers: SurveyAnswers())
        .environmentObject(Router())
}
