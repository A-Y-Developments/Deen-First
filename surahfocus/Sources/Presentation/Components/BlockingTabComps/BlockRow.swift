//
//  BlockRow.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct BlockRow: View {
    var title: String
    var description: String
    var action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.caption))
                    .foregroundColor(Color(hex: "ADA666"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color(hex: "0c292b"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            action()
        }
    }
}
