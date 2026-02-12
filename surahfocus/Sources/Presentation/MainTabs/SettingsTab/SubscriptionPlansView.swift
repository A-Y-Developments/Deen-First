//
//  SubscriptionPlans.swift
//  SurahFocus
//
//  Created by Aditya Rizki on 12/02/26.
//

import SwiftUI

struct SubscriptionPlansView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 28) {
                
                Spacer().frame(height: 40)
                
                // Title
                VStack(spacing: 8) {
                    Text("Unlock Your Quran Journey")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Start your free trial, cancel anytime.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.horizontal, 32)
                
                // Feature Box
                VStack(alignment: .leading, spacing: 16) {
                    
                    PlanFeatureRow(text: "Block distracting apps")
                    PlanFeatureRow(text: "Track your daily streak")
                    PlanFeatureRow(text: "Set time limits & schedules")
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "ADA666").opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Yearly Plan
                ZStack(alignment: .topTrailing) {
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Yearly")
                                .font(.system(.title, design: .serif))
                                .italic()
                                .foregroundColor(Color(hex: "DBDABD"))
                            
                            Text("$29.99")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "DBDABD"))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("7-days Free Trial")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "DBDABD"))
                            
                            Text("$2.49/Mo")
                                .font(.callout)
                                .foregroundColor(Color(hex: "DBDABD"))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "ADA666").opacity(0.2), lineWidth: 1)
                    )
                    
                    // Save 50% label
                    Text("Save 50%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "ADA666"))
                        .foregroundColor(Color(hex: "1A494D"))
                        .rotationEffect(.degrees(5))
                        .offset(x: -24, y: -12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
                
                // Monthly Plan
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("3-days Free Trial")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "AEAEB2"))
                        
                        Text("$4.99/Mo")
                            .font(.callout)
                            .foregroundColor(Color(hex: "AEAEB2"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                
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
        }
    }
}

struct PlanFeatureRow: View {
    var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .foregroundColor(Color(hex: "ADA666"))
            
            Text(text)
                .foregroundColor(Color(hex: "DBDABD"))
                .font(.callout)
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionPlansView()
}
