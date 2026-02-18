//
//  SetupSummary.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 18/02/26.
//

import SwiftUI

struct SetupSummary: View {
    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {

                // Header
                VStack(spacing: 16) {
                    // Navigation
                    HStack {
                        Button {
                            print("chevron left")
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 36)
                
                VStack(spacing: 16) {
                    Text("Here’s a great blocking setup for you to start")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.white)
                    Text("You can edit this anytime later")
                        .font(.system(.callout, weight: .medium))
                        .foregroundStyle(Color.gray4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Music")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("1 app selected • 30 mins/day • Every day")
                        .font(.footnote)
                        .foregroundColor(Color.gray4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary900)
                )
                .padding(.top, 56)
                
                Spacer()
                
                Button {
                    // Action here
                } label: {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.bottom)
            }
            .padding(.top, 40)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SetupSummary()
}
