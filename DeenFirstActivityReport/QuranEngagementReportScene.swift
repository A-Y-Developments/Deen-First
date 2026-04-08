import DeviceActivity
import SwiftUI

/// Scene for the "Quran Engagement Today" dashboard section.
///
/// This section is sourced entirely from the App Group — it doesn't aggregate
/// `DeviceActivityResults`, so the data stream is consumed but ignored. The
/// stream still has to be drained to satisfy `DeviceActivityReportScene`.
struct QuranEngagementReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "QuranEngagementToday")
    let content: (QuranEngagementReport) -> QuranEngagementSectionView

    init(content: @escaping (QuranEngagementReport) -> QuranEngagementSectionView = QuranEngagementSectionView.init) {
        self.content = content
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> QuranEngagementReport {
        // Drain the async stream — required by the protocol even though this
        // section's data lives in the App Group, not in DeviceActivity results.
        for await _ in data {}
        return QuranEngagementReportBuilder.build()
    }
}
