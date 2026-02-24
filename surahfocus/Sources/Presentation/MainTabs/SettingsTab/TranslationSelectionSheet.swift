//
//  TranslationSelectionSheet.swift
//  SurahFocus
//
//  Created by Claude on 23/02/26.
//

import SwiftUI

struct TranslationSelectionSheet: View {
    @Binding var selectedTranslation: TranslationLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 8)

            Text("Translation Language")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(TranslationLanguage.allCases, id: \.self) { language in
                Button {
                    selectedTranslation = language
                    dismiss()
                } label: {
                    HStack {
                        Text(language.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if selectedTranslation == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.secondary400)
                        }
                    }
                    .padding()
                    .background(selectedTranslation == language ? Color.primary700 : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.primary900)
    }
}

#Preview {
    TranslationSelectionSheet(selectedTranslation: .constant(.english))
}
