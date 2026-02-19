//
//  SubscriptionPlans.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SubscriptionPlansView: View {
    @State private var selectedPlan: Plan = .yearly
    
    enum Plan {
        case yearly
        case monthly
    }
    
    var body: some View {
        VStack(spacing: 28) {
                
                Spacer().frame(height: 40)
                
                // Title
                VStack(spacing: 8) {
                    Text("Unlock Your Quran Journey")
                        .font(.system(.largeTitle))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Deen First is your way to a better relationship with your faith. Start your free trial, cancel anytime.")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary400)
                }
                .padding(.horizontal, 32)
                
                // Feature Box
                VStack(alignment: .leading, spacing: 8) {
                    
                    PlanFeatureRow(text: "Block distracting apps")
                    PlanFeatureRow(text: "Track your daily streak")
                    PlanFeatureRow(text: "Set time limits & schedules")
                    PlanFeatureRow(text: "Listen to the Quran with Focus Session")
                    PlanFeatureRow(text: "Build a deeper connection with Allah")
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary500.opacity(0.4), lineWidth: 2)
                )
                .padding(.horizontal, 24)
                
                VStack {
                    // Yearly Plan
                    ZStack(alignment: .topTrailing) {
                        
                        Button {
                            selectedPlan = .yearly
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Yearly")
                                        .font(.system(.title))
                                        .fontWeight(.bold)
                                        .foregroundColor(
                                            selectedPlan == .yearly
                                            ? .black
                                            : Color.gray4
                                        )
                                    
                                    Text("$29.99")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(
                                            selectedPlan == .yearly
                                            ? .black
                                            : Color.gray4
                                        )
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 16) {
                                    Text("7-days Free Trial")
                                        .font(.subheadline)
                                        .foregroundColor(
                                            selectedPlan == .yearly
                                            ? .black
                                            : Color.gray4
                                        )
                                    
                                    Text("$2.49/Mo")
                                        .font(.callout)
                                        .foregroundColor(
                                            selectedPlan == .yearly
                                            ? .black
                                            : Color.gray4
                                        )
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        selectedPlan == .yearly
                                        ? Color.secondary200
                                        : Color.primary500.opacity(0.4)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        Color.primary500.opacity(0.4),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        // Save Badge
                        Text("Save 50%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(5))
                            .offset(x: -24, y: -12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .shadow(
                        color: Color.secondary200.opacity(0.4),
                        radius: 16
                    )
                    
                    
                    // Monthly Plan
                    Button {
                        selectedPlan = .monthly
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Monthly")
                                    .font(.system(.headline, design: .serif))
                                    .fontWeight(.bold)
                                    .foregroundColor(
                                        selectedPlan == .monthly
                                        ? Color(hex: "1A494D")
                                        : .white
                                    )
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 16) {
                                Text("3-days Free Trial")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        selectedPlan == .monthly
                                        ? .black
                                        : Color.gray4
                                    )
                                
                                Text("$4.99/Mo")
                                    .font(.callout)
                                    .foregroundColor(
                                        selectedPlan == .monthly
                                        ? .black
                                        : Color.gray4
                                    )
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    selectedPlan == .monthly
                                    ? Color.secondary200
                                    : Color.primary500.opacity(0.4)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    Color.primary500.opacity(0.4),
                                    lineWidth: 2
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top)
                }
                
                
                // CTA Button
                Button {
                    print("Start trial tapped")
                } label: {
                    Text("Start My Free Trial")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top)
                
                // Restore
                Text("Restore purchase")
                    .font(.footnote)
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.top, 4)
                
                Spacer()
        }
        .background {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

struct PlanFeatureRow: View {
    var text: String
    
    var body: some View {
        HStack(spacing: 12) {
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
    SubscriptionPlansView()
}
