import DeviceActivity
import SwiftUI

/// Scene that aggregates today's `DeviceActivityResults` into a `DeenScoreReport`
/// and hands it to `DeenScoreSectionView` for rendering.
struct DeenScoreReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "DeenScore")
    let content: (DeenScoreReport) -> DeenScoreSectionView

    init(content: @escaping (DeenScoreReport) -> DeenScoreSectionView = DeenScoreSectionView.init) {
        self.content = content
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> DeenScoreReport {
        var totalScreenTimeSeconds = 0

        for await result in data {
            for await segment in result.activitySegments {
                totalScreenTimeSeconds += Int(segment.totalActivityDuration)
            }
        }

        return DeenScoreReportBuilder.build(totalScreenTimeSeconds: totalScreenTimeSeconds)
    }
}
