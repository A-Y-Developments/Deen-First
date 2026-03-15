//
//  ReciterSelectionSheet.swift
//  DeenFirst
//
//  Created by Claude on 23/02/26.
//

import SwiftUI

struct ReciterSelectionSheet: View {
    let reciters: [Reciter]
    @Binding var selectedReciterId: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 8)

            Text("Default Reciter")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(reciters) { reciter in
                Button {
                    selectedReciterId = reciter.id
                    dismiss()
                } label: {
                    HStack {
                        Text(reciter.name)
                            .foregroundColor(.white)
                        Spacer()
                        if selectedReciterId == reciter.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.secondary400)
                        }
                    }
                    .padding()
                    .background(selectedReciterId == reciter.id ? Color.primary700 : Color.clear)
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
    ReciterSelectionSheet(
        reciters: [
            Reciter(id: 1, name: "Mishary Rashid Al Afasy"),
            Reciter(id: 2, name: "Abu Bakr Al Shatri"),
        ],
        selectedReciterId: .constant(1)
    )
}
