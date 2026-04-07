---
name: screen
description: Creates a new SwiftUI screen scaffold for Deen First — View + ViewModel — following project conventions. Pass the feature name and path.
---

# /screen — New SwiftUI Screen

Creates a complete screen scaffold: View + ViewModel, following Deen First conventions.

## Input
- Feature path (e.g. `MainTabs/DashboardTab`, `AyahPool`, `UnblockDurationSelection`)
- Screen name in PascalCase (e.g. `Dashboard`, `AyahPool`, `UnblockDurationSelection`)

---

## Steps

### 1. Resolve file paths
- View: `deenfirst/Sources/Presentation/<feature_path>/<ScreenName>View.swift`
- ViewModel: `deenfirst/Sources/Domain/Services/<ScreenName>ViewModel.swift`

> Note: ViewModels live in `Domain/Services/` per project convention (not in Presentation/).

### 2. Check for existing files
If any of the files already exist — warn the user and stop. Do not overwrite.

### 3. Create ViewModel

```swift
import Foundation
import Combine

@MainActor final class <ScreenName>ViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // TODO: inject services via DIContainer.shared
    // private let myService: MyService

    init() {
        // self.myService = DIContainer.shared.myService
    }

    func onAppear() {
        Task {
            isLoading = true
            do {
                // await myService.fetch()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### 4. Create View

```swift
import SwiftUI

struct <ScreenName>View: View {
    @StateObject private var viewModel = <ScreenName>ViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                // TODO: implement main content
                Text("<ScreenName>")
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .navigationTitle("<Screen Name>")
    }
}

#Preview {
    <ScreenName>View()
}
```

### 5. Print route snippet (do NOT auto-write — show for user to paste)

```
Add to deenfirst/Sources/Core/SceneNavigation/Router.swift:

// In Route enum:
case <screenNameCamelCase>

// In navigationDestination or switch:
case .<screenNameCamelCase>:
    <ScreenName>View()
```

### 6. Remind about DIContainer wiring

If the screen needs a new service:
```
Add to DIContainer.shared:
  lazy var <screenName>Service = <ScreenName>Service()
```

---

## Constraints

- ViewModel: always `@MainActor final class`, conforms to `ObservableObject`
- View: always `struct`, conforms to `View`; use `@StateObject` for ViewModel ownership
- Never access DIContainer directly from a View — inject through ViewModel only
- Never put business logic in View — delegate all logic to ViewModel
- Never query SwiftData from ViewModel directly — always through a Service
- Services accessed via `DIContainer.shared` in ViewModel `init`
- No force unwrap anywhere
- New screens must be reachable via a `Route` case in `Router.swift` — always show the route snippet
