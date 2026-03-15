import SwiftUI

struct BismillahView: View {
    var body: some View {
        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(hex: "4facfe").opacity(0.05))
            .cornerRadius(12)
    }
}
