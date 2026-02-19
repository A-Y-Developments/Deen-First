//
//  Summary2View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary2View: View {

    @State private var fillProgress: CGFloat = 0
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

            VStack(spacing: 24) {

                Spacer()

                Image("dua-hands")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210, height: 120)

                Text("We are with you!")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .multilineTextAlignment(.center)

                Text("You are a few steps away from a distraction-free relationship with the Quran.")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                // Animated Button
                Button(action: {
                    router.replaceWith(.howAppWork(step: 1))
                }) {
                    ZStack {

                        // Base background
                        Capsule()
                            .fill(Color(hex: "#031315"))

                        // White fill animation
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * fillProgress)
                                .animation(.easeInOut(duration: 5), value: fillProgress)
                        }
                        .clipShape(Capsule())

                        // Text
                        Text("Next")
                            .fontWeight(.semibold)
                            .foregroundColor(fillProgress == 1 ? .black : .white)
                    }
                    .frame(height: 50)
                }
                .disabled(fillProgress < 1)
                .opacity(fillProgress < 1 ? 0.7 : 1)

            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
        .onAppear {
            fillProgress = 1
        }
    }
}

#Preview {
    Summary2View()
        .environmentObject(Router())
}
