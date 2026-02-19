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
    
    @State private var progress: CGFloat = 0.0

    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: - Percentage
                Text("19%")
                    .font(.system(size: 40, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(Color.secondary200)
                
                // MARK: - Progress Bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray4.opacity(0.2))
                        .frame(height: 5)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(Color.secondary200)
                        .frame(width: progress, height: 5)
                        .clipShape(Capsule())
                }
                .frame(height: 2)
                .onAppear {
                    startLoading()
                }
                
                // MARK: - Calculating
                Text("Calculating...")
                    .font(.callout)
                    .foregroundColor(Color.white)
                
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
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                router.replaceWith(.summary(step: 1, answers: answers))
            }
        }
    }
    
    private func startLoading() {
        let screenWidth = UIScreen.main.bounds.width - 144

        progress = 0

        withAnimation(.linear(duration: 2)) {
            progress = screenWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            startLoading()
        }
    }


}

#Preview {
    CalculateSurveyView(answers: SurveyAnswers())
        .environmentObject(Router())
}
