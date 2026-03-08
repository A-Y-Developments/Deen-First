//
//  Summary1View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct Summary1View: View {

    @EnvironmentObject private var viewModel: SummaryViewModel
    @EnvironmentObject var router: Router

    let answers: SurveyAnswers

    init(answers: SurveyAnswers = SurveyAnswers()) {
        self.answers = answers
    }

    var body: some View {
        VStack(alignment: .leading) {

            Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Header
                    Text("MashaAllah...")
                        .font(.title)
                        .italic()
                        .foregroundColor(Color.secondary200)

                    // MARK: - Time Highlight (DYNAMIC)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(viewModel.selectedRangeLabel)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.white)

                        Text("hours")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .italic()
                    }

                    // MARK: - Subtitle
                    Text("on \(viewModel.selectedAppsDisplay)?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .italic()
                        .foregroundColor(Color.secondary200)
                }

                // MARK: - Subheading
                Text("That's actually enough time to get:")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(Color.gray4)
                    .padding(.top, 48)

                // MARK: - Container
                VStack(spacing: 16) {

                    // Item 1
                    HStack(spacing: 12) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#AEF29B"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Read \(viewModel.juzAchievement) Juz")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text(viewModel.pagesDescription)
                                .font(.callout)
                                .foregroundColor(Color(hex: "#AEAEB2"))
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))

                    // Item 2
                    HStack(spacing: 12) {
                        Image(systemName: "bookmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#AEF29B"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.surahAchievement)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text("Learned surah Mulk completely")
                                .font(.callout)
                                .foregroundColor(Color(hex: "#AEAEB2"))
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))

                    // Item 3
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#AEF29B"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected Deeply")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text("Spend time with your Creator")
                                .font(.callout)
                                .foregroundColor(Color(hex: "#AEAEB2"))
                        }

                        Spacer()
                    }
                }
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary400.opacity(0.6), lineWidth: 2)

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary400.opacity(0.6), lineWidth: 4)
                            .blur(radius: 8)
                    }
                )
                .padding(.top)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Humans average about 46 hours/week on screens.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary200)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Reclaiming even part of that can become Qur'an, dzikr, and real connection with Allah.")
                        .font(.callout)
                        .foregroundColor(Color.secondary300)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 14)

                Spacer()

                Button(action: {
                    router.navigate(to: .summary(step: 2, answers: viewModel.answers))
                }) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 28)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        .mainBackground()
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.answers = answers
            viewModel.currentStep = 1
        }
    }
}

#Preview {
    Summary1View()
        .environmentObject(SummaryViewModel())
        .environmentObject(Router())
}
