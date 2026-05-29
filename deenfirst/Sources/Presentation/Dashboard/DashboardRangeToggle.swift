import SwiftUI

/// Branded capsule segmented control for the Dashboard's Today / This Week range.
///
/// Replaces the native `.segmented` Picker so the control matches the app's
/// dark-green + lime visual language (track = faint white, selected pill = lime
/// with dark text). The pill slides between options via `matchedGeometryEffect`.
struct DashboardRangeToggle: View {
    @Binding var selection: DashboardDetailViewModel.DateRange
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DashboardDetailViewModel.DateRange.allCases) { range in
                segment(for: range)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: Capsule())
        .accessibilityElement(children: .contain)
    }

    private func segment(for range: DashboardDetailViewModel.DateRange) -> some View {
        let isSelected = range == selection
        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selection = range
            }
        } label: {
            Text(range.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? Color.primary900 : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color(hex: "AEF29B"))
                            .matchedGeometryEffect(id: "selectedPill", in: namespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
