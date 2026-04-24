import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    init(title: String, isLoading: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.primary900)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.white : Color.white.opacity(0.3))
            .foregroundColor(isEnabled ? Color.primary900 : Color.primary900.opacity(0.5))
            .clipShape(Capsule())
        }
        .disabled(!isEnabled || isLoading)
    }
}
