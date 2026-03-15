import StoreKit
import SwiftUI
import UIKit

@MainActor
class SupportViewModel: ObservableObject {
    func requestAppReview() {
        // Request in-app rating prompt
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
