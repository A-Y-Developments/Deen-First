import SwiftUI

struct SessionFinishView: View {
    @EnvironmentObject var router: Router
    let duration: TimeInterval
    let surahCount: Int
    
    var body: some View {
        VStack(spacing: 24) {
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text("MashaAllah...")
                    .font(.system(.title, weight: .semibold))
                    .italic()
                    .foregroundColor(.white)
                
                Text("You’re doing better than 99% of people who just scroll through their phones aimlessly.")
                    .font(.callout)
                    .foregroundColor(Color.secondary200)
                    .multilineTextAlignment(.leading)
                
                Text("May your effort be accepted by Allah")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // ✅ Button di dalam VStack
            Button {
                navigateToHome()
            } label: {
                Text("Aameen")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)
            .shadow(
                color: Color.primary400,
                radius: 12
            )
        }
        .navigationBarHidden(true)
        .padding(24)
        .background {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
    
    private func navigateToHome() {
        router.navigateBack()
        router.navigateBack()
        router.navigateBack()
        router.navigateBack()
    }
}

#Preview {
    SessionFinishView(duration: 300, surahCount: 3)
        .environmentObject(Router())
}
