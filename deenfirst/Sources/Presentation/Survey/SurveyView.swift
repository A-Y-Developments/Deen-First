//
//  Survey.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct SurveyView: View {

    @EnvironmentObject private var viewModel: SurveyViewModel
    @EnvironmentObject var router: Router

    let step: Int
    let answers: SurveyAnswers

    init(step: Int = 1, answers: SurveyAnswers = SurveyAnswers()) {
        self.step = step
        self.answers = answers
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            VStack(spacing: 16) {

                // Navigation
                HStack {
                    if viewModel.canGoBack {
                        Button {
                            withAnimation {
                                viewModel.goBack()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    Spacer()  // Skip button removed
                }

                // MARK: - Indicator (4 Steps)
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                        Rectangle()
                            .fill(
                                index < viewModel.currentStep
                                    ? Color.white
                                    : Color.white.opacity(0.2)
                            )
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
                    }
                }
                .padding(.top)
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 36)

            // MARK: - Content
            TabView(selection: $viewModel.currentStep) {

                SurveyStep1View(viewModel: viewModel)
                    .tag(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())

                SurveyStep2View(viewModel: viewModel)
                    .tag(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())

                SurveyStep3View(viewModel: viewModel)
                    .tag(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())

                SurveyStep4View(viewModel: viewModel)
                    .tag(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                Spacer()

                Button(action: {
                    if viewModel.goNext() {
                        router.navigate(to: .calculateSurvey(answers: viewModel.answers))
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
                    .background(viewModel.canGoNext ? Color.white : Color.gray.opacity(0.5))
                    .clipShape(Capsule())
                }
                .disabled(!viewModel.canGoNext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .mainBackground()
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.answers = answers
            viewModel.currentStep = step
        }
    }
}

#Preview {
    SurveyView()
        .environmentObject(SurveyViewModel())
        .environmentObject(Router())
}
