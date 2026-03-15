//
//  Summary2View.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary2View: View {

    @State private var fillProgress: CGFloat = 0
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("We are with you!")
                .font(.title)
                .bold()
                .foregroundColor(Color.secondary200)
                .multilineTextAlignment(.center)

            Image("dua-hands")
                .resizable()
                .scaledToFit()
                .frame(height: 120)

            Text("You are a few steps away from a distraction-free relationship with the Quran.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: {
                router.navigate(to: .howAppWork(step: 1))
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
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .mainBackground()
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            fillProgress = 1
        }
    }
}

#Preview {
    Summary2View()
        .environmentObject(Router())
}
