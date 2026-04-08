import DeviceActivity
import SwiftUI

/// Scene for the "Weekly Trend" Deen Score chart.
///
/// Buckets each `DeviceActivityResults` segment into its day of origin (using
/// `segment.dateInterval.start`) and hands the resulting per-day screen-time
/// map to `WeeklyTrendReportBuilder`, which combines it with stored App Group
/// counters to compute 7 daily Deen Scores.
///
/// The host is expected to drive this scene with a 7-day daily-segmented
/// `DeviceActivityFilter`. Days outside the stream simply default to zero
/// screen time, so the chart still renders 7 bars even with partial data.
struct WeeklyTrendReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "WeeklyTrend")
    let content: (WeeklyTrendReport) -> WeeklyTrendSectionView

    init(
        content: @escaping (WeeklyTrendReport) -> WeeklyTrendSectionView
            = WeeklyTrendSectionView.init
    ) {
        self.content = content
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> WeeklyTrendReport {
        var screenTimeSecondsByDay: [String: Int] = [:]
        for await result in data {
            for await segment in result.activitySegments {
                let dayKey = DashboardDateKeys.dayKey(for: segment.dateInterval.start)
                screenTimeSecondsByDay[dayKey, default: 0] += Int(segment.totalActivityDuration)
            }
        }
        return WeeklyTrendReportBuilder.build(
            screenTimeSecondsByDay: screenTimeSecondsByDay
        )
    }
}
