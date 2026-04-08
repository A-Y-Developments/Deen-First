import SwiftUI

struct PendingChangeSheet: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(Color.secondary400)

                Text("Disable Lock Editing?")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(.white)

                Text("This request will take effect in 24 hours. You can cancel it anytime before then.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Schedule Disable")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary900)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary400)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary400.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.secondary400.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(24)
        .background(Color.primary900)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
