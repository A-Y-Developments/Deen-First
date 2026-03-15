//
//  StartView.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct StartView: View {

    @State private var activeAyah: Int = 1
    let totalAyah = 7

    var body: some View {
        ZStack {

            // Background
            Color(hex: "041315")
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {

                        ForEach(1...totalAyah, id: \.self) { index in

                            VStack(alignment: .leading, spacing: 12) {

                                Text("1:\(index)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "8E8E93"))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                Text("بِسْمِ ٱللَّٰهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                                    .font(.system(size: 26, design: .serif))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.white)

                                Text("Bismillah hir rahman nir raheem")
                                    .foregroundColor(.white)

                                Text("In the Name of Allah—the Most Compassionate, Most Merciful")
                                    .font(.footnote)
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.primary500.opacity(0.5))
                            .opacity(activeAyah == index ? 1 : 0.3)
                            .blur(radius: activeAyah == index ? 0 : 2)
                            .animation(.easeInOut(duration: 0.4), value: activeAyah)
                            .id(index)
                        }
                    }
                }
                .scrollDisabled(true)  // 🔥 user tidak bisa scroll
                .onChange(of: activeAyah) { oldValue, newValue in
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .onAppear {
                    proxy.scrollTo(activeAyah, anchor: .center)

                    // Simulasi auto progression (demo)
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
                        if activeAyah < totalAyah {
                            activeAyah += 1
                        } else {
                            timer.invalidate()
                        }
                    }
                }
            }

            // MARK: Top Right Close Button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        print("Close tapped")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()

                Spacer()
            }

            // MARK: Bottom Sticky Player
            VStack {
                Spacer()

                HStack {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Al-Baqara")
                            .font(.system(.headline))
                            .foregroundColor(.white)

                        Text("The Cow")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        print("Play tapped")
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color.secondary200)
                    }
                }
                .padding()
                .background(Color.primary500)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding()
        }
    }
}

#Preview {
    StartView()
}
