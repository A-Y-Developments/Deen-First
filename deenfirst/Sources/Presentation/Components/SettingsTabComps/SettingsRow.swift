//
//  SettingsRow.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct SettingsRow: View {
    var title: String
    var icon: String = "chevron.right"

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.primary900)
        .cornerRadius(14)
    }
}
