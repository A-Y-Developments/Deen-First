//
//  PreferencesView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @State private var showTranslationSheet = false
    @State private var showReciterSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

                // MARK: Translation Field
                Button {
                    showTranslationSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation")
                            .font(.callout)
                            .foregroundColor(Color.white)

                        HStack {
                            Text(viewModel.selectedTranslation.displayName)
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.primary700)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                // MARK: Default Reciter Field
                Button {
                    showReciterSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Reciter")
                            .font(.callout)
                            .foregroundColor(Color.white)

                        HStack {
                            Text(reciterName)
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(Color.primary700)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .mainBackground()
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showTranslationSheet) {
            TranslationSelectionSheet(selectedTranslation: $viewModel.selectedTranslation)
        }
        .onChange(of: viewModel.selectedTranslation) { oldValue, newValue in
            viewModel.saveTranslation()
        }
        .sheet(isPresented: $showReciterSheet) {
            ReciterSelectionSheet(
                reciters: viewModel.availableReciters,
                selectedReciterId: $viewModel.selectedReciterId
            )
        }
        .onChange(of: viewModel.selectedReciterId) { oldValue, newValue in
            viewModel.saveReciter()
        }
    }

    private var reciterName: String {
        viewModel.reciterName
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}
