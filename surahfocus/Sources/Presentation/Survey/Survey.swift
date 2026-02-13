//
//  Survey.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Survey: View {
    
    @State private var currentStep: Int = 0
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {

                // MARK: - Header
                VStack(spacing: 16) {
                    
                    // Navigation
                    HStack {
                        if currentStep > 0 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Skip") {
                            currentStep = totalSteps - 1
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // MARK: - Indicator (5 Steps)
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Rectangle()
                                .fill(
                                    index <= currentStep
                                    ? Color.white
                                    : Color.white.opacity(0.2)
                                )
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)
                                .animation(.easeInOut(duration: 0.25), value: currentStep)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 36)
                
                
                // MARK: - Content (Dummy Views)
                TabView(selection: $currentStep) {
                    
                    SurveyStep1View()
                        .tag(0)
                    
                    SurveyStep2View()
                        .tag(1)
                    
                    SurveyStep3View()
                            .tag(2)
                        
                        SurveyStep4View()
                            .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if currentStep < totalSteps - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            print("Survey Finished")
                        }
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
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    Survey()
}
