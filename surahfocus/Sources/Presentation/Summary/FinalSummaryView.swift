//
//  Summary1.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct FinalSummaryView: View {
    @State private var animateButton = false
    @EnvironmentObject var router: Router

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

            VStack(alignment: .leading) {
                Spacer()
                // Impact text
                Text("IMPACT")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))

                // Title
                Text("Reclaim your faith in just 1 days")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)

                // Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#173E41"))

                    Image("khushoo-graph")
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                .frame(height: 200)
                .padding(.top, 20)

                // 87%
                Text("87%")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .padding(.top, 40)

                // Description
                Text("of our users finish their daily Juz consistently after enabling App Blocking.")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)

                Spacer()

                // Button
                Button(action: {
                    Task { await completeOnboarding() }
                }) {
                    Text("Next")
                        .fontWeight(.semibold)
                        .foregroundColor(animateButton ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (animateButton ? Color.white : Color(hex: "#031315"))
                        )
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 6), value: animateButton)
                }
                .disabled(!animateButton)
            }
            .padding(.vertical)
            .padding(.horizontal,20)
        }
        .onAppear {
            animateButton = true
        }
    }

    func completeOnboarding() async {
        guard let user = try? await DIContainer.shared.userRepository.getCurrentUser() else { return }
        user.hasCompletedOnboarding = true
        try? await DIContainer.shared.userRepository.updateUser(user)
        router.replaceWith(.paywall)
    }
}

#Preview {
    FinalSummaryView()
        .environmentObject(Router())
}
