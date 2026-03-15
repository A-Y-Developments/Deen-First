//
//  AyahRangeSheetView.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 22/02/26.
//

import SwiftUI

struct AyahRangeSheetView: View {
    let surah: Surah
    @State var startAyah: Int
    @State var endAyah: Int

    var onSave: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 8)

            Text(surah.name)
                .font(.headline)
                .foregroundColor(.white)

            // MARK: Horizontal Wheel Pickers
            HStack(spacing: 16) {

                // START
                VStack(spacing: 8) {
                    Text("Start")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)

                    Picker("", selection: $startAyah) {
                        ForEach(1...surah.numberOfAyahs, id: \.self) { ayah in
                            Text("\(ayah)")
                                .foregroundColor(.white)
                                .tag(ayah)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }

                // END
                VStack(spacing: 8) {
                    Text("End")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)

                    Picker("", selection: $endAyah) {
                        ForEach(startAyah...surah.numberOfAyahs, id: \.self) { ayah in
                            Text("\(ayah)")
                                .foregroundColor(.white)
                                .tag(ayah)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
            }
            .frame(height: 160)

            Button {
                onSave(startAyah, endAyah)
                dismiss()
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
        .background(Color.primary900)
        .onChange(of: startAyah) { oldValue, newValue in
            if endAyah < newValue {
                endAyah = newValue
            }
        }
    }
}
