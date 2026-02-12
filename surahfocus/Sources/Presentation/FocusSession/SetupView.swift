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
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Focus Session")
                    .font(.system(.title3))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // MARK: Blocked App
                VStack(alignment: .leading, spacing: 12) {
                    Text("Blocked App")
                        .font(.callout)
                        .foregroundColor(Color(hex: "ADA666"))
                    
                    HStack {
                        Text("Select App to Block")
                            .foregroundColor(Color(hex: "8E8E93"))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color(hex: "062023"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // MARK: Surah to Listen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Surah to Listen")
                        .font(.callout)
                        .foregroundColor(Color(hex: "ADA666"))
                    
                    SurahToListen()
                    
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                        Text("Add Surah")
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "062023"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Spacer()
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                print("Start Session tapped")
            } label: {
                Text("Start Session")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "ADA666"))
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
        }
    }
}


#Preview {
    SetupView()
}
