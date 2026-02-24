//
//  PermissionView.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 13/02/26.
//

import SwiftUI
import FamilyControls

struct PermissionView: View {
    @EnvironmentObject private var viewModel: PermissionSetupViewModel
    @EnvironmentObject var router: Router

    var body: some View {
        VStack {
                
                Spacer()
                Spacer()
                
                // MARK: - Shield Image
                Image("shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                
                // MARK: - Title
                Text("Screen Time Permission")
                    .font(.system(.title))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                
                // MARK: - Description
                Text("We need Screen Time permission to block distractions and help you reconnect with the Qur'an.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top)
                
                
                // MARK: - Benefits Container
                VStack(alignment: .leading, spacing: 16) {
                    
                    permissionRow(text: "Permission is key to block distractions")
                    
                    permissionRow(text: "You’re in control of what gets blocked")
                    
                    permissionRow(text: "We never access your personal data")
                }
                .padding(20)
                //                .background(
                //                    RoundedRectangle(cornerRadius: 20)
                //                        .stroke(Color.secondary400.opacity(0.4), lineWidth: 2)
                //                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex:"DBDABD").opacity(0.4), lineWidth: 3)
                        .blur(radius: 4)
                        .opacity(0.6)
                )
                .padding(.horizontal, 24)
                .padding(.top, 48)
                
                
                Spacer()
                
                
                // MARK: - Button
                Button(action: {
                    Task {
                        await viewModel.requestAuthorization()
                        if viewModel.isAuthorized {
                            router.navigate(to: .setupAppToBlock)
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(Color(hex: "031315"))
                        } else {
                            Text("Give permission to Deen First")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "031315"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .mainBackground()
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Retry", role: .cancel) {
                Task {
                    await viewModel.requestAuthorization()
                    if viewModel.isAuthorized {
                        router.navigate(to: .setupAppToBlock)
                    }
                }
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onAppear {
            viewModel.checkAuthorization()
            if viewModel.isAuthorized {
                router.navigate(to: .setupAppToBlock)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    
    // MARK: - Row Component
    private func permissionRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: "checkmark")
                .foregroundColor(Color.secondary200)
            
            Text(text)
                .foregroundColor(Color.secondary200)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionView()
}
