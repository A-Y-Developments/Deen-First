//
//  Summary6.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary6: View {
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "062629"),
                    Color(hex: "041315")
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                
                Spacer()
                
                VStack(spacing: 16) {
                    // MARK: - Header
                    Text("MashaAllah...")
                        .font(.title)
                        .italic()
                        .foregroundColor(Color(hex: "#ADA666"))
                    
                    // MARK: - Time Highlight
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("2.5")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(Color(hex: "#DBDABD"))
                        
                        Text("hours")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "#DBDABD"))
                            .italic()
                    }
                    .padding(.leading, 8)
                    
                    // MARK: - Subtitle
                    Text("on social media?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .italic()
                        .foregroundColor(Color(hex: "#ADA666"))
                }
                
                // MARK: - Subheading
                Text("That's actually enough time to get:")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .padding(.top, 48)
                
                // MARK: - Container
                VStack(spacing: 16) {
                    
                    // Item 1
                    HStack(spacing: 12) {
                        Image("book")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Read 2 Juz")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#D1D1D6"))
                            
                            Text("Finished ~40 pages of Quran")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))
                    
                    // Item 2
                    HStack(spacing: 12) {
                        Image("archive")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Memorized a Surah")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#D1D1D6"))
                            
                            Text("Learned surah Mulk completely")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))
                    
                    // Item 3
                    HStack(spacing: 12) {
                        Image("people")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected Deeply")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#D1D1D6"))
                            
                            Text("Had real conversation with family")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#1A494D").opacity(0.4), lineWidth: 1.5)
                )
                
                
                Spacer()
                
                // MARK: - Continue Button
                Button(action: {
                    print("Continue tapped")
                }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#031315"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
    }
}

#Preview {
    Summary6()
}
