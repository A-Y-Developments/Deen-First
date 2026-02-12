import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                // MARK: - Profile Section
                VStack(spacing: 12) {
                    
                    // Avatar
                    Circle()
                        .fill(Color(hex: "#ADA666"))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("J")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    // Name
                    Text("Jane Doe")
                        .font(.system(.title2, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Email
                    Text("jane.doe@icloud.com")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .padding(.top, 40)
                
                
                // MARK: - Menu Section
                VStack(spacing: 16) {
                    
                    SettingsRow(title: "Subscription")
                    SettingsRow(title: "Preferences")
                    SettingsRow(title: "Help & Support")
                    
                }
                
                // MARK: - Footer
                Text("Terms of Service • Privacy • Sign Out")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .padding(.top, 32)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}
