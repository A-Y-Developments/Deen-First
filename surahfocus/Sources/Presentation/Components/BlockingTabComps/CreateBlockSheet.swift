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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Create New Blocks")
                    .font(.system(.title2))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text("Select the blocking types you want to set")
                    .font(.system(.subheadline))
                    .foregroundColor(Color.gray4)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            BlockRow(
                title: "App Limit",
                description: "Limit selected apps daily usage"
            ) {
                print("app limit focus")
                dismiss()
                router.navigate(to: .appLimit)
            }

            BlockRow(
                title: "Time of Day",
                description: "Block apps during specific time windows"
            ) {
                print("tapped time of day")
                dismiss()
                router.navigate(to: .timeLimit)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.primary900)
    }
}
