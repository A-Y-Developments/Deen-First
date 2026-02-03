//
//  CustomButton.swift
//  surahfocus
//
//  Created by Adithya Firmansyah Putra on 03/02/26.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isDense: Bool = false
    var isFilled: Bool = true
    var isLoading: Bool = false
    var variant: ButtonVariant = .active

    enum ButtonVariant {
        case active
        case disabled
    }

    var body: some View {
        Button(action: action) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                    Text(title)
                        .font(.system(size: isDense ? 14 : 16, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isDense ? 10 : 14)
                .background(buttonColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(8)
            } else {
                Text(title)
                    .font(.system(size: isDense ? 14 : 16, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isDense ? 10 : 14)
                    .background(buttonColor)
                    .foregroundColor(foregroundColor)
                    .cornerRadius(8)
            }
        }
        .disabled(isLoading || variant == .disabled)
    }

    private var buttonColor: Color {
        if isFilled {
            if variant == .disabled || isLoading {
                return Color.gray.opacity(0.3)
            }
            return Color.accentColor
        } else {
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        if isFilled {
            return Color.white
        } else {
            if variant == .disabled || isLoading {
                return Color.gray.opacity(0.3)
            }
            return Color.accentColor
        }
    }
}
