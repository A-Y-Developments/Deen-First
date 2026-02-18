import SwiftUI

struct BlockAppLimitCard: View {
    let settingsName: String
    let appName: String
    let appsCount: Int
    let timeLimit: String
    let daysText: String

    init(
        settingsName: String = "",
        appName: String = "Music",
        appsCount: Int = 2,
        timeLimit: String = "30 mins/day",
        daysText: String = "Every day"
    ) {
        self.settingsName = settingsName
        self.appName = appName
        self.appsCount = appsCount
        self.timeLimit = timeLimit
        self.daysText = daysText
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(settingsName.isEmpty ? appName : settingsName)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .font(.system(.callout))
                    
                    Spacer()
                    
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.7))
                }
                Text("\(appsCount) app\(appsCount == 1 ? "" : "s") selected" + " • \(timeLimit) • \(daysText)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Text("\(appsCount) app\(appsCount == 1 ? "" : "s") selected")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {

                Text(timeLimit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0c292b"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(daysText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0c292b"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "062023"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
