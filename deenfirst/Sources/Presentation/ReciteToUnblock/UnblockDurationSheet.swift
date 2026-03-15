import SwiftUI

struct UnblockDurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reciteToUnblockViewModel: ReciteToUnblockViewModel
    @EnvironmentObject var router: Router

    let ruleId: UUID?
    @State private var selectedMinutes: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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

            VStack(alignment: .leading, spacing: 10) {
                Text("Duration")
                    .foregroundColor(Color.secondary400)
                    .fontWeight(.semibold)

                HStack {
                    Spacer()

                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(1...15, id: \.self) { minute in
                            Text("\(minute) min")
                                .foregroundColor(.white)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(width: 140, height: 150)
                    .clipped()
                    .colorScheme(.dark)

                    Spacer()
                }
                .background(Color.primary500.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                    reciteToUnblockViewModel.targetRuleId = ruleId
                    reciteToUnblockViewModel.unblockDurationMinutes = selectedMinutes
                    dismiss()
                    router.navigate(to: .reciteToUnlock)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(24)
        .background(Color.primary900)
        .onAppear {
            selectedMinutes = min(max(reciteToUnblockViewModel.unblockDurationMinutes, 1), 15)
        }
    }
}
