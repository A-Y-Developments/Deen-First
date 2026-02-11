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
                Text("\(icon ?? "") \(text)")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Color(hex: "DBDABD") : Color(hex: "AEAEB2"))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .background(isSelected ? Color(hex: "1a494d") : Color(hex: "06191c"))
            .cornerRadius(12)
        }
    }
}
