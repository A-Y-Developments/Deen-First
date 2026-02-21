import SwiftUI

struct BlockRuleCard: View {
    let settingsName: String
    let appsCount: Int
    let categoriesCount: Int
    let timeInfo: String
    let daysText: String
    let isShowPencil: Bool

    init(
        settingsName: String = "",
        appsCount: Int = 2,
        categoriesCount: Int = 0,
        timeInfo: String = "30 mins/day",
        daysText: String = "Every day",
        isShowPencil: Bool = true
    ) {
        self.settingsName = settingsName
        self.appsCount = appsCount
        self.categoriesCount = categoriesCount
        self.timeInfo = timeInfo
        self.daysText = daysText
        self.isShowPencil = isShowPencil
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

                Spacer()

                if isShowPencil {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            Text(selectionText + " • \(timeInfo) • \(daysText)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "092621"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
