//
//  PreferencesView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct PreferencesView: View {
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
                
                Text("Preferences")
                    .font(.system(.title3))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // MARK: Translation Field
                VStack(alignment: .leading, spacing: 12) {
                    Text("Translation")
                        .font(.callout)
                        .foregroundColor(Color.white)
                    
                    HStack {
                        Text("English (Sahih International)")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color(hex: "062023"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // MARK: Default Reciter Field
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Reciter")
                        .font(.callout)
                        .foregroundColor(Color.white)
                    
                    HStack {
                        Text("Mishary Alafasy")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(Color(hex: "062023"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    PreferencesView()
}

