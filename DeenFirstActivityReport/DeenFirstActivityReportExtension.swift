import DeviceActivity
import SwiftUI

@main
struct DeenFirstActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DeenFirstActivityReportScene()
    }
}

struct DeenFirstActivityReportScene: DeviceActivityReportScene {
    let configuration = DeviceActivityReport.Context("DeenFirst")
    var body: some View {
        Text("Dashboard loading…")
    }
}
