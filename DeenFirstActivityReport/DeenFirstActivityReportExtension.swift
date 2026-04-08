import DeviceActivity
import SwiftUI

@main
struct DeenFirstActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DeenScoreReportScene()
    }
}
