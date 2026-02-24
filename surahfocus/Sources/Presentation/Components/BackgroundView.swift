import SwiftUI

struct MainBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Image("main-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
    }
}

struct SecondaryBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Image("secondary-background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func mainBackground() -> some View {
        modifier(MainBackgroundModifier())
    }
    func secondaryBackground() -> some View {
        modifier(SecondaryBackgroundModifier())
    }
}
