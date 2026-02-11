//
//  TimeLimit.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct TimeLimitView: View {
    
    @State private var selectedDays: Set<Int> = []
    @State private var selectedPrayer: String? = nil
    
    let days = ["S","M","T","W","T","F","S"]
    let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // HEADER
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Time Limit")
                            .font(.system(.title3))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text("Block app at specific time of day")
                            .font(.system(.subheadline))
                            .foregroundColor(Color(hex: "999999"))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 24) {
                        
                        // BLOCKED APP
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Blocked App")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("Music")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "pencil")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .background(Color(hex: "0c292b"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // SURAH TO LISTEN
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Surah to Listen")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("2 apps")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .background(Color(hex: "0c292b"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // TIME SETTINGS
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time Settings")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            Text("Manual Set")
                                .foregroundColor(Color(hex: "ADA666"))
                                .font(.caption)
                            
                            // START TIME
                            HStack {
                                Text("Start")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Text("2:45 PM")
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(Color(hex: "0c292b"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            // END TIME
                            HStack {
                                Text("End")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Text("2:45 PM")
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(Color(hex: "0c292b"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // PRAYER GRID
                        VStack(alignment: .leading, spacing: 12) {
                            Text("During prayer time")
                                .foregroundColor(Color(hex: "999999"))
                                .font(.caption)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(prayers, id: \.self) { prayer in
                                    let isSelected = selectedPrayer == prayer
                                    
                                    Text(prayer)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            isSelected ?
                                            Color(hex: "ADA666") :
                                                Color(hex: "0c292b")
                                        )
                                        .foregroundColor(
                                            isSelected ?
                                            Color(hex: "0c292b") :
                                                    .white
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .onTapGesture {
                                            selectedPrayer = prayer
                                        }
                                }
                            }
                        }
                        
                        // ACTIVE TIME
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Time")
                                .foregroundColor(Color(hex: "999999"))
                                .font(.caption)
                            
                            HStack(spacing: 12) {
                                ForEach(0..<7) { index in
                                    let isSelected = selectedDays.contains(index)
                                    
                                    Text(days[index])
                                        .fontWeight(.semibold)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            isSelected ?
                                            Color(hex: "ADA666") :
                                                Color(hex: "0c292b")
                                        )
                                        .foregroundColor(
                                            isSelected ?
                                            Color(hex: "0c292b") :
                                                    .white
                                        )
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            if isSelected {
                                                selectedDays.remove(index)
                                            } else {
                                                selectedDays.insert(index)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    
                    // COMPLETE BUTTON
                    Button {
                        print("Complete setup tapped")
                    } label: {
                        Text("Complete setup")
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "0c292b"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "ADA666"))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 12)
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    TimeLimitView()
}

