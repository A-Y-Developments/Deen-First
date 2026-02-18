//
//  SetupView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SetupView: View {
    var body: some View {
        ZStack {
            // Background
            Image("secondary-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Main Content
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Focus Session")
                    .font(.system(.headline))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // MARK: Blocked App
                VStack(alignment: .leading) {
                    Text("Blocked App")
                        .font(.system(.callout, weight: .medium))
                        .foregroundColor(Color.secondary400)
                    
                    HStack {
                        Text("Select App to Block")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.primary500.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // MARK: Surah to Listen
                VStack(alignment: .leading) {
                    Text("Surah to Listen")
                        .font(.system(.callout, weight: .medium))
                        .foregroundColor(Color.secondary400)
                    
                    SurahToListen()
                    
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                        Text("Add Surah")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.primary500.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top)
                
                Spacer()
                
                // MARK: Start Session Button
                Button {
                    print("Start Session tapped")
                } label: {
                    Text("Start Session")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
                // glow effect
                .shadow(
                    color: Color.primary400,
                    radius: 12
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
        }
    }
}


#Preview {
    SetupView()
}
