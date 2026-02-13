//
//  PermissionView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct PermissionView: View {
    
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
                Spacer()
                
                // MARK: - Shield Image
                Image("shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                
                // MARK: - Title
                Text("Screen Time Permission")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                
                // MARK: - Description
                Text("We need Screen Time permission to block distractions and help you reconnect with the Qur'an.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                
                // MARK: - Benefits Container
                VStack(alignment: .leading, spacing: 16) {
                    
                    permissionRow(text: "Permission is key to block distractions")
                    
                    permissionRow(text: "You’re in control of what gets blocked")
                    
                    permissionRow(text: "We never access your personal data")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#ADA666").opacity(0.2), lineWidth: 1.5)
                )
                .padding(.horizontal, 24)
                
                
                Spacer()
                
                
                // MARK: - Button
                Button(action: {
                    print("Give permission tapped")
                }) {
                    Text("Give permission to Surah Focus")
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
    
    
    // MARK: - Row Component
    private func permissionRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: "checkmark")
                .foregroundColor(Color(hex: "#ADA666"))
            
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionView()
}
