//
//  AppLimitView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct AppLimitView: View {
    
    @State private var selectedHour = 1
    @State private var selectedMinute = 0
    @State private var selectedDays: Set<Int> = []
    
    let days = ["S","M","T","W","T","F","S"]
    
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
                        Text("App Limit")
                            .font(.system(.title3))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text("Block app after daily usage limit")
                            .font(.system(.subheadline))
                            .foregroundColor(Color(hex: "999999"))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    
                    // CONTENT
                    VStack(spacing: 24) {
                        
                        // BLOCKED APP
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Blocked App")
                                .foregroundColor(Color(hex: "ADA666"))
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
                                .foregroundColor(Color(hex: "ADA666"))
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
                                .foregroundColor(Color(hex: "ADA666"))
                                .fontWeight(.semibold)
                            
                            Text("App Usage Duration")
                                .foregroundColor(Color(hex: "999999"))
                                .font(.caption)
                            
                            HStack {
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour) hours").tag(hour)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .pickerStyle(.wheel)
                                
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute) min").tag(minute)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .pickerStyle(.wheel)
                            }
                            .frame(height: 120)
                            .background(Color(hex: "0c292b"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
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
                        print("Complete Setup tapped")
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
    AppLimitView()
}
