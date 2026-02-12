//
//  SubscriptionView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 28) {
                Text("Subscription")
                    .font(.system(.title3))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 100)
                    .foregroundColor(Color(hex: "ADA666"))
                Text("MashaAllah\nyou're the premium one")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: "DBDABD"))
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Plan")
                            .foregroundColor(.white)
                            .font(.callout)
                        
                        Spacer()
                        
                        Text("Yearly plan is active")
                            .foregroundColor(Color(hex: "ADA666"))
                            .font(.callout)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2))
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Renewal")
                            .foregroundColor(.white)
                            .font(.callout)
                        
                        Text("Your plan will automatically renew on 9 Feb 2027. You’ll be charged $29.99/year")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2))
                    )
                    HStack {
                        Text("Explore Plans")
                            .foregroundColor(.white)
                            .font(.callout)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color(hex: "062023"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    SubscriptionView()
}
