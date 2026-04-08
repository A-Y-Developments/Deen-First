import SwiftUI

struct BlockRuleCard: View {
    let settingsName: String
    let appsCount: Int
    let categoriesCount: Int
    let timeInfo: String
    let daysText: String

    var isHardMode: Bool
    var showUnblockButton: Bool
    var onUnblock: (() -> Void)?

    /// When non-nil, replaces the Unblock button with a disabled countdown label.
    var countdownDisplay: String?

    init(
        settingsName: String = "",
        appsCount: Int = 2,
        categoriesCount: Int = 0,
        timeInfo: String = "30 mins/day",
        daysText: String = "Every day",
        isHardMode: Bool = false,
        showUnblockButton: Bool = true,
        onUnblock: (() -> Void)? = nil,
        countdownDisplay: String? = nil
    ) {
        self.settingsName = settingsName
        self.appsCount = appsCount
        self.categoriesCount = categoriesCount
        self.timeInfo = timeInfo
        self.daysText = daysText
        self.isHardMode = isHardMode
        self.showUnblockButton = showUnblockButton
        self.onUnblock = onUnblock
        self.countdownDisplay = countdownDisplay
    }

    private var selectionText: String {
        var parts: [String] = []
        if categoriesCount > 0 {
            parts.append("\(categoriesCount) categor\(categoriesCount == 1 ? "y" : "ies")")
        }
        if appsCount > 0 {
            parts.append("\(appsCount) app\(appsCount == 1 ? "" : "s")")
        }
        return parts.isEmpty ? "Nothing selected" : parts.joined(separator: " and ") + " selected"
    }

    private var displayName: String {
        settingsName.isEmpty ? "Block" : settingsName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(displayName)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .font(.system(.callout))

                if isHardMode {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "FF6B35"))
                }

                Spacer()

                if showUnblockButton {
                    if let countdown = countdownDisplay {
                        // Temporarily unblocked — show disabled countdown
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 13, weight: .semibold))
                            Text(countdown)
                                .font(.system(size: 15, weight: .semibold))
                                .monospacedDigit()
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    } else if let onUnblock {
                        // Normal state — show active Unblock button
                        Button {
                            onUnblock()
                        } label: {
                            Text("Unblock")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "ADA666"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "ADA666").opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "ADA666").opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(selectionText + " • \(timeInfo) • \(daysText)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.primary900)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    VStack(spacing: 12) {
        BlockRuleCard(
            settingsName: "Social Media",
            appsCount: 3,
            categoriesCount: 1,
            timeInfo: "1h/day",
            daysText: "Weekdays",
            isHardMode: true,
            onUnblock: { print("Unblock tapped") }
        )
        BlockRuleCard(
            settingsName: "Prayer Time Block",
            appsCount: 0,
            categoriesCount: 2,
            timeInfo: "12:15 PM - 1:30 PM",
            daysText: "Everyday"
            // No onUnblock — button hidden
        )
    }
    .padding()
    .background(Color.primary800)
}