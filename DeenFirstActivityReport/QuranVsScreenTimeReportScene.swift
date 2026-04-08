import DeviceActivity
import SwiftUI

/// Scene for the "Quran vs Screen Time" comparison section.
///
/// Aggregates today's total screen time from `DeviceActivityResults`, then
/// pairs it with the Quran seconds counter from the App Group via
/// `QuranVsScreenTimeReportBuilder`.
struct QuranVsScreenTimeReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "QuranVsScreenTime")
    let content: (QuranVsScreenTimeReport) -> QuranVsScreenTimeSectionView

    init(
        content: @escaping (QuranVsScreenTimeReport) -> QuranVsScreenTimeSectionView
            = QuranVsScreenTimeSectionView.init
    ) {
        self.content = content
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> QuranVsScreenTimeReport {
        var totalScreenTimeSeconds = 0
        for await result in data {
            for await segment in result.activitySegments {
                totalScreenTimeSeconds += Int(segment.totalActivityDuration)
            }
        }
        return QuranVsScreenTimeReportBuilder.build(
            totalScreenTimeSeconds: totalScreenTimeSeconds
        )
    }
}
