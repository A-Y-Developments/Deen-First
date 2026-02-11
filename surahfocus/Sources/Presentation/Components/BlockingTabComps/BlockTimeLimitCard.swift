//
//  BlockTimeLimitCard.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct BlockTimeLimitCard: View {
    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Music")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .font(.system(.callout, design: .serif))
                    
                    Spacer()
                    
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.7))
                }
                Text("2 apps selected")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    
                    Text("2.45 PM - 3.45 PM")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0c292b"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Text("Tue/Wed/Fri/Sat")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0c292b"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Text("Fajr/Maghrib")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0c292b"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "062023"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}


