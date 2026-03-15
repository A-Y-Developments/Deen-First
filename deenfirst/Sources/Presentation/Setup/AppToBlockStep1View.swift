//
//  AppToBlockStep1View.swift
//  DeenFirst
//
//  Created by Aditya Rizki on 13/02/26.
//

import FamilyControls
import SwiftUI

struct AppToBlockStep1View: View {
    @EnvironmentObject private var viewModel: SetupViewModel

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                // MARK: - Small Intro
                Text("Let's go! We got your back")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.gray4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - Title
                Text("Which app distracts you most?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: - Subtitle
                Text("You can select more apps or edit this later")
                    .font(.callout)
                    .foregroundColor(Color.gray4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // MARK: - Illustration
            Image("social-media")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .padding(.vertical, 48)

            // MARK: - Select App Field
            Button {
                viewModel.openPicker()
            } label: {
                HStack {
                    Text(selectionText)
                        .foregroundColor(.white)
                        .font(.body)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary500.opacity(0.4))
                )
            }

            Spacer()
        }
        .padding(.top)
        .familyActivityPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.selection
        )
        .onChange(of: viewModel.selection) { oldValue, newValue in
            viewModel.updateSelection(newValue)
        }
    }

    private var selectionText: String {
        let apps = viewModel.selectedAppsCount
        let categories = viewModel.selectedCategoriesCount

        if apps == 0 && categories == 0 {
            return "Select App"
        } else if apps > 0 && categories > 0 {
            return
                "\(apps) app\(apps == 1 ? "" : "s"), \(categories) categor\(categories == 1 ? "y" : "ies")"
        } else if apps > 0 {
            return "\(apps) app\(apps == 1 ? "" : "s") selected"
        } else {
            return "\(categories) categor\(categories == 1 ? "y" : "ies") selected"
        }
    }
}
