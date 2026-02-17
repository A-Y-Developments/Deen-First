import SwiftUI

struct DowntimeSetupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: OnboardingScreenTimeViewModel

    let prayers = ["subuh", "zuhr", "asr", "maghrib", "isya"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
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

                    if viewModel.selectedAppsCount > 0 {
                        HStack(spacing: 8) {
                            ForEach(0..<min(viewModel.selectedAppsCount, 5), id: \.self) { _ in
                                Image(systemName: "app.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "4facfe"))
                            }

                            if viewModel.selectedAppsCount > 5 {
                                Text("+\(viewModel.selectedAppsCount - 5)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(prayers, id: \.self) { prayer in
                            PrayerTimeCard(
                                prayer: prayer,
                                isSelected: viewModel.isSelected(prayer),
                                timeRange: getPrayerTimeRange(prayer)
                            ) {
                                viewModel.togglePrayer(prayer)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            print("Complete Setup pressed")
                            Task {
                                await viewModel.completeOnboarding()
                                router.navigate(to: .mainTabs)
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                }
                                Text("Complete Setup")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
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
                        .disabled(viewModel.isLoading)

                        Button("Skip") {
                            Task {
                                await viewModel.completeOnboarding()
                                router.navigate(to: .mainTabs)
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Error message display
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            logDowntimeSettings()
        }
    }

    private func logDowntimeSettings() {
        print("=== TIME BLOCK SETTINGS LOG ===")

        let categoryCount = viewModel.selectedCategoriesCount
        let appCount = viewModel.selectedAppsCount

        for prayer in viewModel.selectedPrayers {
            let range = getPrayerTimeRange(prayer)
            print("\nType: Time of Day")
            print("Name: During \(getPrayerDisplayName(prayer))")
            print(
                "App Selection: \(categoryCount) Category\(categoryCount == 1 ? "" : "es"), \(appCount) App\(appCount == 1 ? "" : "s")"
            )
            print("Time: \(range.start) - \(range.end)")
            print("Days: All Days")
        }

        print("\n==============================")
    }

    private func getPrayerTimeRange(_ prayer: String) -> (start: String, end: String) {
        switch prayer {
        case "subuh": return ("04:30", "06:00")
        case "zuhr": return ("12:15", "13:30")
        case "asr": return ("15:45", "17:00")
        case "maghrib": return ("18:15", "19:15")
        case "isya": return ("19:30", "20:45")
        default: return ("00:00", "23:59")
        }
    }

    private func getPrayerDisplayName(_ prayer: String) -> String {
        switch prayer {
        case "subuh": return "Fajr"
        case "zuhr": return "Dhuhr"
        case "asr": return "Asr"
        case "maghrib": return "Maghrib"
        case "isya": return "Isha"
        default: return prayer
        }
    }
}

struct PrayerTimeCard: View {
    let prayer: String
    let isSelected: Bool
    let timeRange: (start: String, end: String)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(getPrayerEmoji(prayer))
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(getPrayerDisplayName(prayer))
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
            let end = formatter.date(from: range.end)
        else {
            return "\(range.start) - \(range.end)"
        }

        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func getPrayerDisplayName(_ prayer: String) -> String {
        switch prayer {
        case "subuh": return "Fajr"
        case "zuhr": return "Dhuhr"
        case "asr": return "Asr"
        case "maghrib": return "Maghrib"
        case "isya": return "Isha"
        default: return prayer
        }
    }

    private func getPrayerEmoji(_ prayer: String) -> String {
        switch prayer {
        case "subuh": return "🌙"
        case "zuhr": return "☀️"
        case "asr": return "🌤️"
        case "maghrib": return "🌅"
        case "isya": return "🌃"
        default: return "🕌"
        }
    }
}

#Preview {
    DowntimeSetupView()
        .environmentObject(Router())
        .environmentObject(OnboardingScreenTimeViewModel())
}
