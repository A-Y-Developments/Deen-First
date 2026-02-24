import SwiftUI
import UIKit

struct TappableText: View {
    let text: String
    let url: String
    let foregroundColor: Color

    init(_ text: String, url: String, foregroundColor: Color = .blue) {
        self.text = text
        self.url = url
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            Text(text)
                .font(.caption)
                .foregroundStyle(foregroundColor)
                .underline()
        }
        .buttonStyle(.plain)
    }
}
