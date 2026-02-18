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
            Image("main-background")
                .resizable()
                .scaledToFill()
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
                Image("app-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 100)
                Text("MashaAllah\nyou're the premium one")
                    .font(.system(.title3, weight: .semibold))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.secondary200)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Plan")
                            .foregroundColor(.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("Yearly plan is active")
                            .foregroundColor(Color.secondary300)
                            .font(.callout)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary700, lineWidth: 2)
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Renewal")
                            .foregroundColor(.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                        
                        Text("Your plan will automatically renew on 9 Feb 2027. You’ll be charged $29.99/year")
                            .foregroundColor(Color.gray4)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary700, lineWidth: 2)
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
                    .background(Color.primary700)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SubscriptionView()
}
