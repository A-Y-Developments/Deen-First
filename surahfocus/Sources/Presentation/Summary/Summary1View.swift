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

    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(alignment: .leading) {

                Spacer()

                VStack(spacing: 16) {
                    // MARK: - Header
                    Text("MashaAllah...")
                        .font(.title)
                        .italic()
                        .foregroundColor(Color.secondary200)

                    // MARK: - Time Highlight (DYNAMIC)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(viewModel.calculatedHours)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.white)

                        Text("hours")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .italic()
                    }
                    .padding(.leading, 8)

                    // MARK: - Subtitle
                    Text("on social media?")
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
                        Image("book")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Read 2 Juz")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text("Finished ~40 pages of Quran")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#AEAEB2"))
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))

                    // Item 2
                    HStack(spacing: 12) {
                        Image("archive")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Memorized a Surah")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text("Learned surah Mulk completely")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "#AEAEB2"))
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color(hex: "#1A494D").opacity(0.4))

                    // Item 3
                    HStack(spacing: 12) {
                        Image("people")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected Deeply")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.gray4)

                            Text("Had real conversation with family")
                                .font(.caption2)
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

                Spacer()

                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("tapped")
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.black)
                        .padding(.vertical)
                        .padding(.horizontal, 28)
                        .background(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 32)

            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
    }
}

#Preview {
    Summary1View()
        .environmentObject(SummaryViewModel())
        .environmentObject(Router())
}
