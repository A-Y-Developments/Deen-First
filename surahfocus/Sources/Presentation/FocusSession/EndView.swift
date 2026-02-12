//
//  EndView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct EndView: View {
    
    var body: some View {
        ZStack {
            
            // Background
            Color(hex: "041315")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("MashaAllah...")
                        .font(.title)
                        .italic()
                        .foregroundColor(.white)
                    
                    Text("You’re doing better than 99% of people who just scroll through their phones aimlessly.")
                        .font(.callout)
                        .foregroundColor(Color(hex: "ADA666"))
                        .multilineTextAlignment(.leading)
                    
                    Text("May your effort be accepted by Allah")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                print("Aameen tapped")
            } label: {
                Text("Aameen")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "ADA666"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(Color(hex: "041315"))
        }
    }
}

#Preview {
    EndView()
}
