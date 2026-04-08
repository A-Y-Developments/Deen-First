import FamilyControls
import SwiftUI

struct AppLimitView: View {
    @EnvironmentObject private var viewModel: AppLimitViewModel
    @Environment(\.dismiss) private var dismiss

    let limitId: UUID?

    private let days = ["S", "M", "T", "W", "T", "F", "S"]

    init(limitId: UUID? = nil) {
        self.limitId = limitId
    }

    var body: some View {
        ZStack {
            Color.primary900.ignoresSafeArea()

            if viewModel.isLoading && viewModel.settingsName.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.secondary400))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection

                        VStack(spacing: 20) {
                            settingsNameSection
                            blockedAppsSection
                            timeSettingsSection
                            activeTimeSection
                            unblockDifficultySection
                        }

                        actionButtons
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
        }
        .task {
            guard let limitId else { return }
            if let rule = DIContainer.shared.screenTimeRulesService.getRule(id: limitId) {
                await viewModel.setupForEdit(rule: rule)
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Block?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCurrentLimit()
                    if viewModel.hasSetupCompleted { dismiss() }
                }
            }
        } message: {
            Text(
                "This will remove the block and its associated shield. This action cannot be undone."
            )
        }
        .familyActivityPicker(
            isPresented: $viewModel.showAppPicker,
            selection: $viewModel.appSelection
        )
        .onChange(of: viewModel.appSelection) { _, newValue in
            Task { await viewModel.handleAppPickerSelection(newValue) }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(viewModel.isEditMode ? "Edit App Limit" : "App Limit")
                .font(.system(.title3, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Text("Block app after daily usage limit")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Settings Name

    private var settingsNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name Settings")
                .foregroundColor(Color.secondary400)
                .fontWeight(.semibold)

            HStack {
                TextField(
                    "",
                    text: $viewModel.settingsName,
                    prompt: Text("Enter a name").foregroundColor(.white.opacity(0.6))
                )
                .foregroundColor(.white)
                .submitLabel(.done)

                Image(systemName: "pencil")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.primary500.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Blocked Apps

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blocked Apps")
                .foregroundColor(Color.secondary400)
                .fontWeight(.semibold)

            Button {
                viewModel.addMoreApps()
            } label: {
                HStack {
                    Text(viewModel.appsCountText)
                    .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color.primary500.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Time Settings (Inline Wheel Picker)

    private var timeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Settings")
                .foregroundColor(Color.secondary400)
                .fontWeight(.semibold)

            Text("App Usage Duration")
                .foregroundColor(.white.opacity(0.6))
                .font(.caption)

            HStack(spacing: 0) {
                Picker("Hours", selection: $viewModel.selectedHours) {
                    ForEach(0..<24, id: \.self) { Text("\($0) hours").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, maxHeight: 150)

                Picker("Minutes", selection: $viewModel.selectedMinutes) {
                    ForEach(0..<60, id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, maxHeight: 150)
            }
            .colorScheme(.dark)
            .background(Color.primary500.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Active Time

    private var activeTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Time")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)

                Spacer()

                Button {
                    viewModel.toggleAllDay()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isAllDay ? "checkmark.square.fill" : "square")
                            .foregroundColor(
                                viewModel.isAllDay ? Color.secondary400 : .white.opacity(0.6))
                        Text("Daily")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let isSelected = viewModel.activeDays.contains(index)
                    Text(days[index])
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(isSelected ? Color.primary600 : Color.primary500.opacity(0.2))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { viewModel.toggleDay(index) }
                }
            }
        }
    }

    // MARK: - Unblock Difficulty

    private var unblockDifficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unblock Difficulty")
                .foregroundColor(Color.secondary400)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                difficultyOption(label: "Normal", isSelected: !viewModel.isHardMode) {
                    viewModel.isHardMode = false
                }
                difficultyOption(label: "Hard Mode", isSelected: viewModel.isHardMode) {
                    viewModel.isHardMode = true
                }
            }

            if viewModel.isHardMode {
                Text("You won't be able to refresh ayahs. A higher recitation score is required. Editing this rule requires a 24-hour delay.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 4)
            }
        }
    }

    private func difficultyOption(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.secondary400 : .white.opacity(0.4))
                    .font(.system(size: 16))
                Text(label)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.primary500.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isEditMode {
            VStack(spacing: 12) {
                deleteButton
                completeButton(title: "Save")
            }
        } else {
            completeButton(title: "Complete Setup")
        }
    }

    private var deleteButton: some View {
        Button {
            viewModel.showDeleteConfirmation = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete Blocks")
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color.secondary400)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary400.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.secondary400.opacity(0.3), lineWidth: 1))
        }
        .disabled(viewModel.isLoading)
    }

    private func completeButton(title: String) -> some View {
        Button {
            Task {
                await viewModel.saveSettings()
                if viewModel.hasSetupCompleted { dismiss() }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.primary900))
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(
                            viewModel.isFormValid ? Color.primary900 : .white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(viewModel.isFormValid ? Color.white : Color.primary500.opacity(0.4))
        .clipShape(Capsule())
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
    }
}

#Preview {
    AppLimitView()
        .environmentObject(AppLimitViewModel())
}
