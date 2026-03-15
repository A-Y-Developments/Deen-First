import SwiftUI

struct EmergencyUnblockView: View {
    @StateObject private var viewModel = EmergencyUnblockViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: - Explanation Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Emergency Unblock")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Instantly removes all blocks until midnight. Use when you have an urgent need.")
                    .font(.subheadline)
                    .foregroundColor(Color.gray4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary700)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // MARK: - Quota
            HStack {
                Text("Uses remaining this week")
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.quotaRemaining) of 2")
                    .foregroundColor(viewModel.quotaRemaining == 0 ? Color.red : Color.secondary400)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.primary700)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // MARK: - Countdown (only when active)
            if viewModel.isActive, let secs = viewModel.secondsUntilMidnight {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color.secondary400)
                    Text("Unblocked for \(formatTime(secs))")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.primary700)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()

            // MARK: - Toggle Button
            Button {
                Task { await viewModel.toggle() }
            } label: {
                Text(viewModel.isActive ? "Deactivate Emergency Unblock" : "Activate Emergency Unblock")
                    .font(.system(.body, weight: .semibold))
                    .foregroundColor(viewModel.isActive ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isActive ? Color.red.opacity(0.8) : Color.secondary400)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.quotaRemaining == 0 && !viewModel.isActive)
            .opacity((viewModel.quotaRemaining == 0 && !viewModel.isActive) ? 0.4 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .mainBackground()
        .navigationTitle("Emergency Unblock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.refresh() }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
