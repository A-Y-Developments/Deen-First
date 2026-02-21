//
//  PreferencesView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
                
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
                    .background(Color.primary700)
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
                    .background(Color.primary700)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .background {
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}