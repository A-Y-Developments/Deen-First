//
//  EmptyBlocksView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct EmptyBlocksView: View {
    @Binding var showCreateSheet: Bool
    
    var body: some View {
        VStack {
            ZStack {
                // Outer rounded box
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary500.opacity(0.4))
                    .frame(width: 100, height: 100)
                
                // Inner circle
                Circle()
                    .fill(Color.secondary400)
                    .frame(width: 64, height: 64)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.primary800)
            }
            .onTapGesture {
                showCreateSheet = true
            }
            Text("No blocks yet")
                .font(.system(.title3))
                .fontWeight(.semibold)
                .foregroundStyle(Color.white)
                .padding(.top, 32)
            Text("Tap plus (+) to add blocking app and manage your focus session")
                .font(.system(.caption, design: .serif))
                .foregroundColor(Color.secondary400)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 110)
                .padding(.top, 10)
        }
        
    }
}

