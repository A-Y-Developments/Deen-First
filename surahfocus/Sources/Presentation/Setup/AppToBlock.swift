//
//  AppToBlock.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlock: View {
    
    @State private var currentStep: Int = 2
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            
            // Main Content
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
                        } else {
                            // prevent glitch
                            Button {
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0))
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
                    .padding(.top, 8)
                }
                .padding(.top, 16)
                .padding(.bottom, 36)
                
                
                // MARK: - Content (Dummy Views)
                TabView(selection: $currentStep) {
                    
                    AppToBlockStep1View()
                        .tag(0)
                    
                    AppToBlockStep2View()
                        .tag(1)
                    
                    AppToBlockStep3View()
                        .tag(2)
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
                            Image(systemName: "arrow.right")
                        }
//                        .foregroundColor(.white)
                        .foregroundColor(.black)
                        .padding(.vertical)
                        .padding(.horizontal, 28)
//                        .background(Color.primary900)
                        .background(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 40)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    AppToBlock()
}
