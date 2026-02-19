//
//  SetupSummary.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 18/02/26.
//

import SwiftUI
import FamilyControls

struct SetupSummary: View {
    @EnvironmentObject private var viewModel: SetupViewModel
    @EnvironmentObject var router: Router

    var body: some View {
        ZStack {
            // Background
            Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {

                // Header
                VStack(spacing: 16) {
                    // Navigation
                    HStack {
                        Button {
                            router.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 36)

                VStack(spacing: 16) {
                    Text("Here's a great blocking setup for you to start")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.white)
                    Text("You can edit this anytime later")
                        .font(.system(.callout, weight: .medium))
                        .foregroundStyle(Color.gray4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 0) {
                        // App Limit Section
                        if viewModel.previewAppLimitRule != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("App Limit")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "ADA666"))
                                    .padding(.horizontal, 24)

                                if let rule = viewModel.previewAppLimitRule {
                                    BlockAppLimitCard(
                                        settingsName: rule.name,
                                        appName: selectionText(for: rule),
                                        appsCount: rule.applicationTokenData.count,
                                        timeLimit: rule.limitDisplayName ?? "N/A",
                                        daysText: rule.daysDisplayText
                                    )
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top, 32)
                        }

                        // Prayer Times Section
                        if !viewModel.previewTimeOfDayRules.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Prayer Times")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "ADA666"))
                                    .padding(.horizontal, 24)

                                ForEach(viewModel.previewTimeOfDayRules) { rule in
                                    BlockTimeLimitCard(
                                        settingsName: rule.name,
                                        appName: selectionText(for: rule),
                                        appsCount: rule.applicationTokenData.count,
                                        timeRange: rule.timeRangeDisplay ?? "N/A",
                                        daysText: rule.daysDisplayText,
                                        prayersText: ""
                                    )
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top, viewModel.previewAppLimitRule == nil ? 32 : 20)
                        }
                    }
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.saveSetup()
                        router.replaceWith(.mainTabs)
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                                .padding(.trailing, 8)
                        }
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .disabled(viewModel.isLoading || !viewModel.hasAnyRules)
                .padding(.bottom)
            }
            .padding(.top, 40)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
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

#Preview {
    SetupSummary()
}
