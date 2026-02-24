//
//  SupportView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI
import UIKit

struct SupportView: View {
    @EnvironmentObject var viewModel: SupportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    Button {
                        if let url = URL(string: AppConstants.Links.faqURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Help & FAQ")
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.primary700)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: AppConstants.Links.contactEmail) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Contact Support")
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.primary700)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.requestAppReview()
                    } label: {
                        HStack {
                            Text("Rate the App")
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.primary700)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 32)

                Spacer()
        }
        .padding(.horizontal, 24)
        .mainBackground()
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}