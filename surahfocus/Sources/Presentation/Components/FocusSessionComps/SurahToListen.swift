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
            HStack(spacing: 6) {
                Text("Ayah")
                    .foregroundColor(.white)
                
                Menu {
                    Picker("Start Ayah", selection: $startAyah) {
                        ForEach(1...286, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                } label: {
                    Text("\(startAyah)")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "ADA666"))
                }
                
                Text("To")
                    .foregroundColor(.white)
                
                Menu {
                    Picker("End Ayah", selection: $endAyah) {
                        ForEach(1...286, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                } label: {
                    Text("\(endAyah)")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "ADA666"))
                }
            }
            .font(.system(.body))
            
        }
        .padding(20)
        .background(Color(hex: "041315").ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
