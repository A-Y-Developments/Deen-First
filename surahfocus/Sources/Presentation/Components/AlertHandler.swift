import SwiftUI

struct AlertHandler: ViewModifier {
    let isError: Binding<Bool>
    let errorMessage: Binding<String?>

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: isError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage.wrappedValue ?? "An error occurred")
            }
    }
}

extension View {
    func errorAlert(isError: Binding<Bool>, errorMessage: Binding<String?>) -> some View {
        self.modifier(AlertHandler(isError: isError, errorMessage: errorMessage))
    }
}
