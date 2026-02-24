//
//  HowAppWork1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct HowAppWork1View: View {

    @EnvironmentObject var router: Router

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

                Spacer()

                // Small Label
                Text("HOW IT WORKS?")
                    .font(.callout)
                    .foregroundColor(Color.secondary400)

                // Title
                Text("Select the app that distracting you")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primary500.opacity(0.2))

                    Image("how-app-work-1")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 40)
                }
                .frame(height: 360)
                .padding(.top, 10)

                // Description
                Text("You identify the problem. We provide the solution.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(Color.secondary200)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
                    .lineLimit(nil)

                Spacer()

                // Right-aligned Button
                HStack {
                    Spacer()

                    Button(action: {
                        router.navigate(to: .howAppWork(step: 2))
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)

                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(Color(hex: "031315"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 16)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top)
        .padding(.bottom, 48)
        .mainBackground()
    }
}

#Preview {
    HowAppWork1View()
        .environmentObject(Router())
}
