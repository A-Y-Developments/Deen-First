//
//  Summary2View.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary2View: View {

    @EnvironmentObject var router: Router

    let answers: SurveyAnswers

    init(answers: SurveyAnswers = SurveyAnswers()) {
        self.answers = answers
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("We spend on average")
                    .font(.title2)
                    .foregroundColor(Color.secondary300)
                    .multilineTextAlignment(.center)

                Text("46 hours")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(Color.secondary200)
                    .multilineTextAlignment(.center)

                Text("every week on screens.")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text(
                "We help you take some of that time back and turn it into Qur'an time, dhikr, and closeness to Allah."
            )
            .font(.subheadline)
            .foregroundColor(Color.secondary300)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)

            Spacer()

            Button(action: {
                router.navigate(to: .summary(step: 3, answers: answers))
            }) {
                HStack(spacing: 8) {
                    Text("Next")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 28)
                .background(.white)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        .mainBackground()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    Summary2View()
        .environmentObject(Router())
}
