import SwiftUI
import FamilyControls

@MainActor
final class ScreenTimePermissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authCenter = AuthorizationCenter.shared

    func checkAuthorization() {
        isAuthorized = authCenter.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await authCenter.requestAuthorization(for: .individual)
            isAuthorized = authCenter.authorizationStatus == .approved

            if !isAuthorized {
                errorMessage = "Permission was denied. You can enable it later in Settings."
                showError = true
            }
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
            showError = true
        }
    }

    func skip() {
        // User can skip, but they'll need to grant permission later
    }
}
