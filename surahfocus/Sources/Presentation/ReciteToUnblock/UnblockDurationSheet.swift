import SwiftUI

struct UnblockDurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @EnvironmentObject var router: Router

    let ruleId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Unblock for how long?")
                    .font(.system(.title2))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                Text("Recite an ayah to temporarily unblock")
                    .font(.system(.subheadline))
                    .foregroundColor(Color.gray4)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            BlockRow(title: "5 Minutes", description: "Short break to check something") {
                reciteToUnblockViewModel.targetRuleId = ruleId
                reciteToUnblockViewModel.unblockDurationMinutes = 5
                dismiss()
                router.navigate(to: .reciteToUnlock)
            }

            BlockRow(title: "15 Minutes", description: "A bit more time to get something done") {
                reciteToUnblockViewModel.targetRuleId = ruleId
                reciteToUnblockViewModel.unblockDurationMinutes = 15
                dismiss()
                router.navigate(to: .reciteToUnlock)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.primary900)
    }
}
