//
//  BlockAppLimitCard.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct BlockAppLimitCard: View {
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
                    
                    Text("30 mins/day")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0c292b"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Text("Every day")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0c292b"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "062023"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

