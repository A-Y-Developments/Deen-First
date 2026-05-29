import SwiftUI

/// Shared section header for the dashboard cards rendered inside
/// `DeenFirstActivityReport`. A lime-tinted SF Symbol + white title, with an
/// optional trailing accessory (e.g. the weekly-trend delta chip).
struct DashboardSectionHeader<Trailing: View>: View {
    private let icon: String
    private let title: String
    private let trailing: Trailing

    init(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DashboardTheme.accent)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DashboardTheme.textPrimary)
            Spacer(minLength: 8)
            trailing
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
