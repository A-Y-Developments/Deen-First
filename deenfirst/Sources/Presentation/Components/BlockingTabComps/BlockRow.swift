//
//  BlockRow.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct BlockRow: View {
    var title: String
    var description: String
    var action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(.caption))
                    .foregroundColor(Color.gray4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.primary500.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            action()
        }
    }
}
