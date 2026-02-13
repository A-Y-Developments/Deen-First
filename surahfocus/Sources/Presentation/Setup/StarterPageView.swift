//
//  StarterPageView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct StarterPageView: View {
    
    var body: some View {
        ZStack {
            
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            
            // MARK: - Content
            VStack(spacing: 24) {
                
                Spacer()
                
                // MARK: - Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "#ADA666").opacity(0.2), lineWidth: 1.5)
                    
                    Image("starter-page")
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                }
                .padding(.horizontal, 24)
                
                
                // MARK: - Small Title
                Text("How does Surah Focus work?")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#DBDABD"))
                
                
                // MARK: - Main Title
                Text("Take action with sessions")
                    .font(.system(.title2, design: .default))
                    .fontWeight(.bold)
                    .italic()
                    .foregroundColor(Color(hex: "#ADA666"))
                
                
                // MARK: - Description
                Text("Remember, you can still watch cat videos – just not too many today. Let’s reset, refresh, and refocus. It's time for a spiritual break!")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#AEAEB2"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                
                Spacer()
                
                
                // MARK: - Button
                Button(action: {
                    print("Let’s Begin tapped")
                }) {
                    Text("Let’s Begin")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "031315"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    StarterPageView()
}
