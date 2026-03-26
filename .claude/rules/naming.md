# Naming Conventions

## Files & Types

- Views: `<Feature>View.swift` → `struct <Feature>View: View`
- ViewModels: `<Feature>ViewModel.swift` → `@MainActor final class <Feature>ViewModel: ObservableObject`
- Services: `<Feature>Service.swift` → `final class <Feature>Service`
- Repositories: `<Feature>Repository.swift` → protocol + `<Feature>RepositoryImpl`
- Entities: `<Name>.swift` → `@Model final class <Name>`
- DataSources: `<Name>DataSource.swift` (remote) or `<Name>Store.swift` (local)
- Components: `<Name>View.swift` in `Presentation/Components/`

## Swift conventions

- Types: `PascalCase`
- Methods, properties, variables: `camelCase`
- Constants: `camelCase` (Swift convention, not `UPPER_SNAKE`)
- Protocols: `<Name>` or `<Name>able` (no `I` prefix)
- Extensions: `<TypeName>+<Purpose>.swift` (e.g. `ScreenTimeRulesService+Unblock.swift`)
- Enum cases: `camelCase`

## App Group keys (AppGroupConstants.swift)

All keys in `AppGroupConstants` as `static let` strings. Pattern: `com.aydev.deenfirst.<purpose>`.
Never hardcode inline.

## Branch names

`feature/df-{ticket-number}-{2-4-word-kebab-slug}`
`fix/df-{ticket-number}-{2-4-word-kebab-slug}`

Examples:
- `feature/df-5-hard-mode-toggle`
- `fix/df-12-pending-change-clock`
