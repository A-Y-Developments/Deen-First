import SwiftUI

struct LoadingOverlay: View {
    let text: String

    init(text: String = "Loading...") {
        self.text = text
    }

    var body: some View {
        ProgressView()
            .tint(.white)
    }
}
