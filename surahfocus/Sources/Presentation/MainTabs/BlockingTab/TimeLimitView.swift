//
//  TimeLimitView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI
import FamilyControls

struct TimeLimitView: View {
    @StateObject private var viewModel: TimeLimitViewModel
    @Environment(\.dismiss) private var dismiss

    let days = ["S", "M", "T", "W", "T", "F", "S"]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(limitId: UUID? = nil, container: DIContainer = .shared) {
        self._viewModel = StateObject(wrappedValue: TimeLimitViewModel(
            limitId: limitId,
            timeLimitService: container.timeLimitSettingsService,
            userRepository: container.userRepository
        ))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "062629"),
                    Color(hex: "041315")
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // HEADER
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.isEditMode ? "Edit Time Limit" : "Time Limit")
                            .font(.system(.title3))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        Text("Block app at specific time of day")
                            .font(.system(.subheadline))
                            .foregroundColor(Color(hex: "999999"))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }

                    // CONTENT
                    VStack(spacing: 24) {

                        // SETTINGS NAME
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Settings Name")
                                .foregroundColor(Color(hex: "ADA666"))
                                .fontWeight(.semibold)

                            TextField("", text: $viewModel.settingsName, prompt: Text("Enter a name"))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "0c292b"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .submitLabel(.go)
                        }

                        // BLOCKED APP
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Blocked App")
                                .foregroundColor(Color(hex: "ADA666"))
                                .fontWeight(.semibold)

                            Button {
                                viewModel.addMoreApps()
                            } label: {
                                HStack {
                                    Text(viewModel.appsCount > 0 ? "\(viewModel.appsCount) apps selected" : "Select apps")
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(Color(hex: "0c292b"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(viewModel.isLoading)
                        }

                        // TIME SETTINGS
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time Settings")
                                .foregroundColor(Color(hex: "ADA666"))
                                .fontWeight(.semibold)

                            Text("Manual Set")
                                .foregroundColor(Color(hex: "999999"))
                                .font(.caption)

                            // START TIME
                            Button {
                                viewModel.showTimePicker = .start
                            } label: {
                                HStack {
                                    Text("Start")
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text(viewModel.startTimeText)
                                        .foregroundColor(.white)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                                .background(Color(hex: "0c292b"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(viewModel.isLoading)

                            // END TIME
                            Button {
                                viewModel.showTimePicker = .end
                            } label: {
                                HStack {
                                    Text("End")
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text(viewModel.endTimeText)
                                        .foregroundColor(.white)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                                .background(Color(hex: "0c292b"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(viewModel.isLoading)
                        }

                        // PRAYER TIME
                        VStack(alignment: .leading, spacing: 12) {
                            Text("During prayer time")
                                .foregroundColor(Color(hex: "999999"))
                                .font(.caption)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(DowntimeSchedule.PrayerTime.allCases, id: \.self) { prayer in
                                    let isSelected = viewModel.selectedPrayers.contains(prayer.rawValue)

                                    Button {
                                        viewModel.togglePrayer(prayer.rawValue)
                                    } label: {
                                        Text(prayer.displayName)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                isSelected ?
                                                Color(hex: "ADA666") :
                                                Color(hex: "0c292b")
                                            )
                                            .foregroundColor(
                                                isSelected ?
                                                Color(hex: "0c292b") :
                                                .white
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                }
                            }
                        }

                        // ACTIVE TIME
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Active Time")
                                    .foregroundColor(Color(hex: "999999"))
                                    .font(.caption)

                                Spacer()

                                Toggle("", isOn: $viewModel.isAllDay)
                                    .labelsHidden()
                            }

                            HStack(spacing: 12) {
                                ForEach(0..<7) { index in
                                    let isSelected = viewModel.activeDays.contains(index)

                                    Text(days[index])
                                        .fontWeight(.semibold)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            isSelected ?
                                            Color(hex: "ADA666") :
                                            Color(hex: "0c292b")
                                        )
                                        .foregroundColor(
                                            isSelected ?
                                            Color(hex: "0c292b") :
                                            .white
                                        )
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            viewModel.toggleDay(index)
                                        }
                                }
                            }
                        }
                    }

                    // COMPLETE BUTTON
                    if viewModel.isEditMode {
                        // Edit mode: Delete + Save buttons
                        HStack(spacing: 12) {
                            Button {
                                viewModel.showDeleteConfirmation = true
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Delete")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                            .disabled(viewModel.isLoading)

                            Button {
                                Task {
                                    await viewModel.saveSettings()
                                    if viewModel.hasSetupCompleted {
                                        dismiss()
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save")
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "0c292b"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "ADA666"))
                            .clipShape(Capsule())
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.top, 12)
                    } else {
                        // Create mode: Single button
                        Button {
                            Task {
                                await viewModel.saveSettings()
                                if viewModel.hasSetupCompleted {
                                    dismiss()
                                }
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .foregroundColor(.white)
                            } else {
                                Text("Complete setup")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "0c292b"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "ADA666"))
                        .clipShape(Capsule())
                        .disabled(viewModel.isLoading)
                        .padding(.top, 12)
                    }
                }
                .padding(24)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Delete Block?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCurrentLimit()
                    if viewModel.hasSetupCompleted {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will remove the block and its associated shield. This action cannot be undone.")
        }
        .sheet(item: $viewModel.showTimePicker) { pickerType in
            TimePickerSheet(
                selectedTime: pickerType == .start ? $viewModel.startTime : $viewModel.endTime,
                title: pickerType == .start ? "Start Time" : "End Time"
            ) { time in
                // Time is updated via binding
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.showAppPicker,
            selection: $viewModel.appSelection
        )
        .onChange(of: viewModel.appSelection) { _, newValue in
            Task {
                await viewModel.handleAppPickerSelection(newValue)
            }
        }
    }
}

#Preview {
    TimeLimitView()
}
