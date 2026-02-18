//
//  SupportView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SupportView: View {
    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Main Content
            VStack(alignment: .leading, spacing: 24) {
                Text("Help & Support")
                    .font(.system(.title3))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Help & FAQ")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color.primary700)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    HStack {
                        Text("Contact Support")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color.primary700)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    HStack {
                        Text("Rate the App")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color.primary700)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 32)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
        }
    }
}

#Preview {
    SupportView()
}


