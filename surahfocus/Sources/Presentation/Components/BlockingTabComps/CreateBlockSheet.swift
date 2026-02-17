//
//  CreateBlockSheet.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 11/02/26.
//

import SwiftUI

struct CreateBlockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: Router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header dengan X button
            HStack {
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Create New Blocks")
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text("Select the blocking types you want to set")
                    .font(.system(.subheadline))
                    .foregroundColor(Color(hex: "ADA666"))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            
            // Menu 1
            BlockRow(
                title: "App Limit",
                description: "Limit selected apps daily usage"
            ) {
                print("app limit focus")
                dismiss()
                router.navigate(to: .appLimit)
            }

            // Menu 2
            BlockRow(
                title: "Time of Day",
                description: "Block apps during specific time windows"
            ) {
                print("tapped time of day")
                dismiss()
                router.navigate(to: .timeLimit)
            }

            // Menu 3
            BlockRow(
                title: "All Day",
                description: "Block apps for entire days"
            ) {
                print("tapped all day")
                dismiss()
                // TODO: Add allDay navigation
            }

            Spacer()
        }
        .padding(24)
        .background(Color(hex: "041315"))
    }
}
