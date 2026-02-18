//
//  SurahToListen.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SurahToListen: View {
    
    @State private var startAyah: Int = 1
    @State private var endAyah: Int = 286
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Surah Header
            HStack {
                Text("Al-Baqaraa")
                    .font(.system(.title3))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    print("Close tapped")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title3)
                }
            }
            
            
            // Ayah Range
            HStack(spacing: 32) {
                Text("Ayah \(startAyah) - \(endAyah)")
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.system(.body))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.primary500.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(20)
        .background(Color.primary500.opacity(0.3)).ignoresSafeArea()
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
