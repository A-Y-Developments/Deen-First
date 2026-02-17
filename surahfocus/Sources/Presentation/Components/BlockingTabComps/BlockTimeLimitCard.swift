import SwiftUI

struct BlockTimeLimitCard: View {
    let settingsName: String
    let appName: String
    let appsCount: Int
    let timeRange: String
    let daysText: String
    let prayersText: String

    init(
        settingsName: String = "",
        appName: String = "Music",
        appsCount: Int = 2,
        timeRange: String = "2.45 PM - 3.45 PM",
        daysText: String = "Tue/Wed/Fri/Sat",
        prayersText: String = "Fajr/Maghrib"
    ) {
        self.settingsName = settingsName
        self.appName = appName
        self.appsCount = appsCount
        self.timeRange = timeRange
        self.daysText = daysText
        self.prayersText = prayersText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(settingsName.isEmpty ? appName : settingsName)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .font(.system(.callout, design: .serif))

                Spacer()
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

                Text(timeRange)
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
            Text(prayersText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(hex: "0c292b"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "062023"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
