//
//  AppToBlock.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct AppToBlock: View {
    @EnvironmentObject private var viewModel: SetupViewModel
    @EnvironmentObject var router: Router

    @State private var currentStep: Int = 0
    @State private var showValidationError = false

    private let totalSteps = 3
    
    var body: some View {
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

                        // Skip button removed per user request
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture())

                    AppToBlockStep2View()
                        .tag(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture())

                    AppToBlockStep3View()
                        .tag(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture())
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
                            // Navigate to SetupSummary
                            router.navigate(to: .setupSummary)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(shouldDisableNextButton() ? .white.opacity(0.5) : .black)
                        .padding(.vertical)
                        .padding(.horizontal, 28)
                        .background(shouldDisableNextButton() ? Color.white.opacity(0.3) : Color.white)
                        .clipShape(Capsule())
                    }
                    .disabled(shouldDisableNextButton())
                }
                .padding(.bottom, 32)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
        .mainBackground()
        .ignoresSafeArea(.all, edges: .top)
        .alert("Required", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please select at least one app or category to continue.")
        }
        .navigationBarBackButtonHidden(true)
    }

    private func shouldDisableNextButton() -> Bool {
        switch currentStep {
        case 0: // App selection
            return viewModel.selectedAppsCount == 0 && viewModel.selectedCategoriesCount == 0
        case 1: // Time limit - must select one
            return viewModel.selectedDailyLimit == nil
        case 2: // Prayer times
            return false // Can skip
        default:
            return false
        }
    }
}

#Preview {
    AppToBlock()
}
