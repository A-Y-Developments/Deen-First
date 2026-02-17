import SwiftUI

struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    var title: String
    var onConfirm: (Int) -> Void

    init(selectedMinutes: Int, title: String, onConfirm: @escaping (Int) -> Void) {
        self.title = title
        self.onConfirm = onConfirm
        self._selectedHours = State(initialValue: selectedMinutes / 60)
        self._selectedMinutes = State(initialValue: selectedMinutes % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text(title)
                    .font(.headline)
                    .padding(.top)

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: $selectedHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 150)
                        .clipped()
                    }

                    VStack(spacing: 8) {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: $selectedMinutes) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 150)
                        .clipped()
                    }
                }

                Spacer()
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let totalMinutes = selectedHours * 60 + selectedMinutes
                        onConfirm(totalMinutes == 0 ? 1 : totalMinutes)
                        dismiss()
                    }
                    .disabled(selectedHours == 0 && selectedMinutes == 0)
                }
            }
        }
    }
}

#Preview {
    DurationPickerSheet(selectedMinutes: 60, title: "App Usage Duration") { _ in }
}
