//
//  EmptyBlocksView.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct EmptyBlocksView: View {
    @Binding var showCreateSheet: Bool

    var body: some View {
        VStack {
            ZStack {
                // Outer rounded box
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary500.opacity(0.4))
                    .frame(width: 100, height: 100)

                // Inner circle
                Circle()
                    .fill(Color.secondary400)
                    .frame(width: 64, height: 64)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.primary800)
            }
            .onTapGesture {
                showCreateSheet = true
            }
            Text("No blocks yet")
                .font(.system(.title3))
                .fontWeight(.semibold)
                .foregroundStyle(Color.white)
                .padding(.top, 32)
            Text(
                "Tap (+) to create a block.\nChoose to block entire categories or specific apps.\n\nWhen your time limit is reached and you get notified, return here to request more time. Recite an Ayah to unlock your phone for an additional 5 or 15 minutes."
            )
            .font(.system(.callout, design: .serif))
            .foregroundColor(Color.secondary400)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }

    }
}
