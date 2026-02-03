//
//  HomeView.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Surah Focus")
                .font(.system(size: 24, weight: .bold, design: .monospaced))

            Text("Read Quran to unlock apps")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)

            Button(action: {
                router.navigate(to: .quran)
            }) {
                Text("Go to Quran")
                    .font(.system(size: 16, design: .monospaced))
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
