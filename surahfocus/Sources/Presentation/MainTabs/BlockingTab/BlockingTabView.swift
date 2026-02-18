import SwiftUI
import FamilyControls

struct BlockingTabView: View {
    @StateObject private var viewModel = BlockingTabViewModel()
    @State private var showCreateSheet = false
    @EnvironmentObject var router: Router

    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Main Content
            ScrollView {
                VStack {
                    HStack {
                        Text("Blocks")
                            .font(.system(.title))
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)


            //         if viewModel.isLoading {
            //             ProgressView()
            //                 .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "ADA666")))
            //                 .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                 .frame(height: 200)
            //         } else if !viewModel.hasApps {
            //             emptyStateView
            //         } else {
            //             blockedAppsContent
            //         }

            //         Spacer()
            //     }
            // }

                    
                    // if blocks empty
                    //                    Spacer()
                    //                    EmptyBlocksView(showCreateSheet: $showCreateSheet)
                    
                    // if blocks exist
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Limit")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "ADA666"))
                        BlockAppLimitCard()
                        BlockAppLimitCard()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Limit")
                            .font(.system(.callout))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "ADA666"))
                        BlockTimeLimitCard()
                        BlockTimeLimitCard()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .padding(.top, 52)

        }
        .sheet(isPresented: $showCreateSheet) {
            CreateBlockSheet()
                .environmentObject(router)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "041315"))
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
        .onAppear {
            Task {
                await viewModel.loadBlockedApps()
            }
        }
        .onChange(of: router.navigationPath.count) { _, _ in
            // Reload when navigation path changes (returning from edit/create screens)
            Task {
                await viewModel.loadBlockedApps()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No blocks set up yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Add apps to block during your Quran focus sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showCreateSheet = true
            }) {
                Text("Create First Block")
                    .font(.headline)
                    .foregroundColor(Color(hex: "0c292b"))
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color(hex: "ADA666"))
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxHeight: .infinity)
    }

    private var blockedAppsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !viewModel.appLimits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Limit")
                        .font(.system(.callout))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "ADA666"))

                    ForEach(viewModel.appLimits) { limit in
                        Button {
                            router.navigate(to: .editAppLimit(id: limit.id))
                        } label: {
                            BlockAppLimitCard(
                                settingsName: limit.name,
                                appName: selectionText(for: limit),
                                appsCount: limit.applicationTokenData.count,
                                timeLimit: limit.limitDisplayName ?? "N/A",
                                daysText: limit.daysDisplayText
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }

            if !viewModel.timeOfDayLimits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time of Day")
                        .font(.system(.callout, design: .serif))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "ADA666"))

                    ForEach(viewModel.timeOfDayLimits) { limit in
                        Button {
                            router.navigate(to: .editTimeLimit(id: limit.id))
                        } label: {
                            BlockTimeLimitCard(
                                settingsName: limit.name,
                                appName: selectionText(for: limit),
                                appsCount: limit.applicationTokenData.count,
                                timeRange: limit.timeRangeDisplay ?? "N/A",
                                daysText: limit.daysDisplayText,
                                prayersText: "None"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }

            if !viewModel.allDayLimits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Day")
                        .font(.system(.callout, design: .serif))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "ADA666"))

                    ForEach(viewModel.allDayLimits) { limit in
                        Button {
                            router.navigate(to: .editAllDay(id: limit.id))
                        } label: {
                            BlockAppLimitCard(
                                settingsName: limit.name,
                                appName: selectionText(for: limit),
                                appsCount: limit.applicationTokenData.count,
                                timeLimit: "All Day",
                                daysText: limit.daysDisplayText
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    private func selectionText(for rule: ScreenTimeRule) -> String {
        let selection = rule.getFamilyActivitySelection()
        let apps = selection.applicationTokens.count
        let categories = selection.categoryTokens.count

        if apps == 0 && categories == 0 {
            return "No selection"
        } else if apps > 0 && categories > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s"), \(categories) categor\(categories == 1 ? "y" : "ies")"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s")"
        } else {
            return "\(categories) categor\(categories == 1 ? "y" : "ies")"
        }
    }
}
