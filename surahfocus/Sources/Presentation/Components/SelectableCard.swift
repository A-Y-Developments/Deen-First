import SwiftUI

struct SelectableCard: View {
    let text: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(text: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 24))
                }

                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "4facfe") : .white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
                    .foregroundStyle(.secondary)
            )
        }
    }
}
