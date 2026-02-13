//
//  Summary4.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary4: View {
    @State private var selectedIndex: Int? = nil
    
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
            
            VStack(alignment: .leading, spacing: 20) {
                
                Spacer()
                
                // Label
                Text("THE EXCHANGE")
                    .font(.callout)
                    .foregroundColor(Color(hex: "#ADA666"))
                
                // Title
                Text("Turn wasted screen time into eternal rewards")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#DBDABD"))
                    .multilineTextAlignment(.leading)
                
                // OPTIONS STACK
                VStack(spacing: 32) {
                    
                    ExchangeOptionCard(
                        index: 0,
                        selectedIndex: $selectedIndex,
                        title: "30m social media",
                        subtitle: "Recite surah Yasin",
                        isHighlighted: false
                    )
                    
                    ExchangeOptionCard(
                        index: 1,
                        selectedIndex: $selectedIndex,
                        title: "1h doomscrolling",
                        subtitle: "Complete 1 Juz",
                        isHighlighted: true
                    )
                    
                    ExchangeOptionCard(
                        index: 2,
                        selectedIndex: $selectedIndex,
                        title: "15m Shorts/Reels",
                        subtitle: "Read 4 pages of Quran",
                        isHighlighted: false
                    )
                }
                .padding(.top, 10)
                
                // Bottom Text
                Text("Small blocks of time add up to a Khatam.")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#ADA666"))
                    .padding(.top, 10)
                
                Spacer()
                
                // Button Right
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("Next tapped")
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(Color(hex: "031315"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
    }
}

#Preview {
    Summary4()
}

struct ExchangeOptionCard: View {
    
    let index: Int
    @Binding var selectedIndex: Int?
    
    let title: String
    let subtitle: String
    let isHighlighted: Bool
    
    var isSelected: Bool {
        selectedIndex == index
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // CARD CONTENT
            VStack(alignment: .leading, spacing: 8) {
                
                Text(title)
                    .strikethrough()
                    .foregroundColor(Color(hex: "#8E8E93"))
                
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(
                        isSelected
                        ? Color(hex: "#DBDABD")
                        : (isHighlighted
                           ? Color(hex: "#DBDABD")
                           : Color(hex: "#D1D1D6"))
                    )
            }
            .padding()
            .padding(.top, isHighlighted ? 10 : 0) // kasih ruang untuk badge
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                ? Color(hex: "#102D30")
                : Color(hex: "#102D30").opacity(0.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected
                        ? Color(hex: "#DBDABD")
                        : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            
            // FLOATING BADGE
            if isHighlighted {
                Text("Most Common")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#1A494D"))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(hex: "#ADA666"))
                    .clipShape(Capsule())
                    .offset(x: 16, y: -12) // 👈 overflow ke atas
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
            }
        }
    }

}

