import DeviceActivity
import SwiftUI

/// Thin host view for the Dashboard tab.
///
/// All content is rendered by the `DeenFirstActivityReport` extension via
/// `DeviceActivityReport`. The extension is known to crash silently and
/// render a black view; the fallback placeholder is layered *behind* the
/// report so the user always sees a message instead of an empty screen.
struct DashboardTabView: View {
    private enum DateRange: String, CaseIterable, Identifiable {
        case today
        case thisWeek

        var id: String { rawValue }

        var label: String {
            switch self {
            case .today: return "Today"
            case .thisWeek: return "This Week"
            }
        }
    }

    private let context = DeviceActivityReport.Context(rawValue: "DeenScore")

    @State private var dateRange: DateRange = .today
    @State private var refreshNonce = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Range", selection: $dateRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    ZStack {
                        fallbackPlaceholder
                        DeviceActivityReport(context, filter: filter)
                            .id(refreshNonce)
                    }
                    .frame(minHeight: 360)
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                refreshNonce &+= 1
            }
            .navigationTitle("Dashboard")
        }
        .mainBackground()
    }

    private var fallbackPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            Text("Dashboard unavailable")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("Pull down to refresh.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dashboard unavailable. Pull down to refresh.")
    }

    private var filter: DeviceActivityFilter {
        switch dateRange {
        case .today:
            let interval = Calendar.current.dateInterval(of: .day, for: .now)
                ?? DateInterval(start: .now, duration: 86_400)
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone])
            )
        case .thisWeek:
            let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now)
                ?? DateInterval(start: .now, duration: 86_400 * 7)
            return DeviceActivityFilter(
                segment: .weekly(during: interval),
                users: .all,
                devices: .init([.iPhone])
            )
        }
    }
}
