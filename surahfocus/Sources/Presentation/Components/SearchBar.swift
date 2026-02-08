import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            ZStack {
                if text.isEmpty {
                    HStack {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                    }
                }
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}
