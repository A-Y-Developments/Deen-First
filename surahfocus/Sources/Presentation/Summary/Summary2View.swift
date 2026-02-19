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
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

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
                    .frame(width: 400, height: 120)

                Text("You are a few steps away from a distraction-free relationship with the Quran.")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("tapped")
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.black)
                        .padding(.vertical)
                        .padding(.horizontal, 28)
                        .background(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 64)
                .padding(.trailing, 32)

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
