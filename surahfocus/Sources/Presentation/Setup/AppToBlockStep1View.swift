//
//  AppToBlockStep1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlockStep1View: View {
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                // MARK: - Small Intro
                Text("Let's go! We got your back")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.gray4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // MARK: - Title
                Text("Which app distracts you most?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // MARK: - Subtitle
                Text("You can select more apps or edit this later")
                    .font(.callout)
                    .foregroundColor(Color.gray4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // MARK: - Illustration
            Image("social-media")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .padding(.vertical, 48)
            
            
            // MARK: - Select App Field
            HStack {
                Text("Select App")
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary500.opacity(0.4))
            )
        
            Spacer()
        }
        .padding(.top)
    }
}
