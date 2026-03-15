//
//  Summary1.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct FinalSummaryView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            // Impact text
            Text("IMPACT")
                .font(.callout)
                .foregroundColor(Color.secondary400)

            // Title
            Text("Reclaim your faith in just 1 days")
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // Image Container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary500.opacity(0.4))

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
                .foregroundColor(Color.secondary200)
                .padding(.top, 40)

            // Description
            (Text("of our users finish their daily ")
                .foregroundColor(Color.secondary300)
                + Text("Ayah")
                .bold()
                .foregroundColor(Color.secondary200)
                + Text(" consistently after enabling App Blocking.")
                .foregroundColor(Color.secondary300))
                .font(.callout)
                .multilineTextAlignment(.leading)
                .padding(.top, 2)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text("Now, it’s your turn.")
                .font(.callout)
                .foregroundColor(Color.secondary300)
                .multilineTextAlignment(.leading)
                .padding(.top, 16)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Button
            Button(action: {
                Task { await completeOnboarding() }
            }) {
                Text("I’m Ready to Start")
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)
        }
        .padding(.top)
        .padding(.bottom, 48)
        .padding(.horizontal, 20)
        .mainBackground()
    }

    func completeOnboarding() async {
        guard let user = try? await DIContainer.shared.userRepository.getCurrentUser() else {
            return
        }
        user.hasCompletedOnboarding = true
        try? await DIContainer.shared.userRepository.updateUser(user)

        NotificationCenter.default.post(name: .didCompleteOnboarding, object: nil)
    }
}

#Preview {
    FinalSummaryView()
        .environmentObject(Router())
}
