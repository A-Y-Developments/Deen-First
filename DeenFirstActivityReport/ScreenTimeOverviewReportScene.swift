import DeviceActivity
import SwiftUI

/// Scene that aggregates today's `DeviceActivityResults` into a `ScreenTimeOverviewReport`
/// and hands it to `ScreenTimeOverviewSectionView` for rendering.
struct ScreenTimeOverviewReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "ScreenTimeOverview")
    let content: (ScreenTimeOverviewReport) -> ScreenTimeOverviewSectionView

    init(
        content: @escaping (ScreenTimeOverviewReport) -> ScreenTimeOverviewSectionView
            = ScreenTimeOverviewSectionView.init
    ) {
        self.content = content
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ScreenTimeOverviewReport {
        var totalScreenTimeSeconds = 0
        var totalPickups = 0
        var rawUsages: [TopAppsAggregator.AppUsage] = []

        for await result in data {
            for await segment in result.activitySegments {
                totalScreenTimeSeconds += Int(segment.totalActivityDuration)

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        totalPickups += appActivity.numberOfPickups
                        rawUsages.append(
                            TopAppsAggregator.AppUsage(
                                bundleId: appActivity.application.bundleIdentifier,
                                displayName: appActivity.application.localizedDisplayName,
                                durationSeconds: Int(appActivity.totalActivityDuration)
                            )
                        )
                    }
                }
            }
        }

        let topApps = TopAppsAggregator.topApps(from: rawUsages)
        let hoursSinceMidnight = Self.hoursSinceMidnight(now: Date())

        return ScreenTimeOverviewReport(
            totalScreenTimeSeconds: totalScreenTimeSeconds,
            pickupCount: totalPickups,
            hoursSinceMidnight: hoursSinceMidnight,
            topApps: topApps
        )
    }

    /// Hours elapsed since local midnight, clamped to `[0, 24]`.
    static func hoursSinceMidnight(now: Date, calendar: Calendar = .current) -> Double {
        let startOfDay = calendar.startOfDay(for: now)
        let elapsed = now.timeIntervalSince(startOfDay)
        return max(0, min(24, elapsed / 3600))
    }
}
