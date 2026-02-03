import SwiftUI

struct DowntimeSetupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: DowntimeSetupViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    VStack(spacing: 16) {
                        Text("Block during prayer times? (Optional)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Apps will be blocked during selected prayer times")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    if !viewModel.selectedApps.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.selectedApps.prefix(5)), id: \.self) { _ in
                                Image(systemName: "app.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "4facfe"))
                            }

                            if viewModel.selectedApps.count > 5 {
                                Text("+\(viewModel.selectedApps.count - 5)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(DowntimeSchedule.PrayerTime.allCases, id: \.self) { prayer in
                            PrayerTimeCard(
                                prayer: prayer,
                                isSelected: viewModel.isSelected(prayer),
                                timeRange: viewModel.getTimeRange(for: prayer)
                            ) {
                                viewModel.togglePrayer(prayer)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            viewModel.save()
                            router.navigate(to: .mainTabs)
                        } label: {
                            Text("Complete Setup")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }

                        Button("Skip") {
                            viewModel.skip()
                            router.navigate(to: .mainTabs)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            loadSelectedApps()
        }
    }

    private func loadSelectedApps() {
        guard let sharedDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let appDataArray = sharedDefaults.array(forKey: "selectedAppsForSetup") as? [Data] else {
            return
        }

        viewModel.loadApps(appDataArray)
    }
}

struct PrayerTimeCard: View {
    let prayer: DowntimeSchedule.PrayerTime
    let isSelected: Bool
    let timeRange: (start: String, end: String)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(prayer.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(formatTimeRange(timeRange))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "4facfe"))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color(hex: "4facfe") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    private func formatTimeRange(_ range: (start: String, end: String)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: range.start),
              let end = formatter.date(from: range.end) else {
            return "\(range.start) - \(range.end)"
        }

        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

#Preview {
    DowntimeSetupView()
        .environmentObject(Router())
        .environmentObject(DowntimeSetupViewModel())
}
