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

            VStack(alignment: .leading, spacing: 20) {

                Spacer()

                // Small Label
                Text("THE MECHANISM")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))

                // Title
                Text("We interrupt the scroll to open the Quran")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .multilineTextAlignment(.leading)

                // Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#173E41"))

                    Image("phone-to-quran")
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                .frame(height: 220)
                .padding(.top, 10)

                // Description
                Text("When you try to open social apps, we gently guide you to your Quran goal.")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#ADA666"))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 10)

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
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
    }
}

#Preview {
    HowAppWork1View()
        .environmentObject(Router())
}
