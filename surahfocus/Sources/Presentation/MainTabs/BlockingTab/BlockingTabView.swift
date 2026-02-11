import SwiftUI

struct BlockingTabView: View {
    @State private var showCreateSheet = false
    @EnvironmentObject var router: Router
    
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
            ScrollView {
                VStack {
                    // Header
                    HStack {
                        Text("Blocks")
                            .font(.system(.title, design: .serif))
                            .fontWeight(.semibold)
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
                    
                    // if blocks empty
                    //                Spacer()
                    //                EmptyBlocksView(showCreateSheet: $showCreateSheet)
                    
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
                            .font(.system(.callout, design: .serif))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "ADA666"))
                        BlockTimeLimitCard()
                        BlockTimeLimitCard()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateBlockSheet()
                .environmentObject(router)
                .presentationDetents([.fraction(0.5), .medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "041315"))
        }
        
    }
}





