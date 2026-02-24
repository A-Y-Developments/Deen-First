//
//  HowAppWork2View.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI

struct HowAppWork2View: View {
    @State private var selectedIndex: Int? = nil
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

                Spacer()

                // Small Label
                Text("BUILD A HABIT")
                    .font(.callout)
                    .foregroundColor(Color.secondary400)

                // Title
                Text("Locked out? Recite an ayah to enter")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Image Container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primary500.opacity(0.2))

                    Image("how-app-work-2")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 40)
                }
                .frame(height: 360)
                .padding(.top, 10)

                // Description
                Text("When you try to open a blocked app, we intervene. By reciting, you build a better habit.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(Color.secondary200)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button(action: {
                    router.navigate(to: .howAppWork(step: 3))
                }) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(Color(hex: "031315"))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top)
        .padding(.bottom, 48)
        .mainBackground()
    }
}

#Preview {
    HowAppWork2View()
        .environmentObject(Router())
}
