# boilerkit

A Swift CLI tool that interactively scaffolds a production-ready Xcode project following a strict VIPER/RIBs architecture. Answer a few questions and get a fully-wired `.xcodeproj` — complete with build configurations, schemes, SwiftData persistence, localizations, an optional onboarding flow, and a tab-based navigation shell — ready to open and run.

## Requirements

- macOS 13+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Installation

```sh
git clone https://github.com/KociucKy/boilerkit
cd boilerkit
make install        # builds release binary and copies to /usr/local/bin
```

To uninstall:

```sh
make uninstall
```

---

## Usage

### Generate a project

```sh
boilerkit
# or explicitly:
boilerkit generate
```

This launches the interactive wizard. Answer each numbered question and a complete Xcode project is generated in your output directory.

### Manage defaults

```sh
boilerkit config                          # show current defaults
boilerkit config --output ~/Developer     # set default output directory
boilerkit config --team-id ABCD1234       # set default Apple Team ID
boilerkit config --clear-output           # clear default output directory
boilerkit config --clear-team-id          # clear default Team ID
```

Defaults are stored at `~/.boilerkit/config.json`. When a default is set, the wizard skips that question and shows the stored value inline instead.

---

## The Wizard

Running `boilerkit` starts an interactive prompt. Questions are asked in a fixed order. Sub-prompts (deployment targets, tab details, language selection) are indented continuations of their parent step.

### Wizard questions

| # | Question | Input style | Default |
|---|---|---|---|
| 1 | App name | text | _(required)_ |
| 2 | Bundle ID | text | `com.yourcompany.<appname>` |
| 3 | Apple Team ID | text | _(skipped if stored)_ |
| 4 | Target platforms | multiselect | iOS only |
| 5 | Deployment targets | text per platform | per-platform OS minimum |
| 6 | Swift version | text | `6.0` |
| 7 | SwiftData | yes/no | yes |
| 8 | Localizations | yes/no + multiselect | no |
| 9 | Code quality tools | multiselect | SwiftLint on, SwiftFormat off |
| 10 | Tabs | number + text per tab | _(required, 1–6)_ |
| 11 | DevSettings | yes/no | no |
| 12 | Onboarding | yes/no | no |
| 13 | Packages | multiselect + free text | NavigationKit (always included) |
| 14 | Output directory | text | _(skipped if stored)_ |

Run `boilerkit generate --help` for a full description of every question.

### Full example session

```
  🏗️  boilerkit
  iOS app project generator
  ──────────────────────────────────────

  👉 App name (e.g. MyApp, no spaces): MyApp
  👉 Bundle ID [com.yourcompany.myapp]: com.acme.myapp
  Team ID: ABCD1234 (default — run 'boilerkit config' to change)

  📱 Platforms (iOS is always included):

     ▶ [ ]  macOS  (Mac Catalyst / native macOS)
       [ ]  watchOS  (Apple Watch)
       [ ]  tvOS  (Apple TV)
       [ ]  visionOS  (Apple Vision Pro)
     ↑↓ move   Space toggle   Enter confirm

  Deployment targets (press Enter to accept defaults):
     iOS [18.0]:
  👉 Swift version [6.0]:
  👉 Use SwiftData for persistence? [Y/n]: y
     First entity name (e.g. Item), or press Enter to skip: Task
  👉 Add localizations? [y/N]: y

  🌍 Languages (English is always included):

     ▶ [ ]  Polish  (pl)
       [ ]  German  (de)
       ...
     ↑↓ move   Space toggle   Enter confirm

  🔧 Code quality tools:

     ▶ [x]  SwiftLint  (linting)
       [ ]  SwiftFormat  (formatting)
     ↑↓ move   Space toggle   Enter confirm

  👉 Number of tabs (1–6): 3

  Configure each tab (name + SF Symbol):
  Tab 1:
      Name (e.g. Home): Home
      SF Symbol [circle]: house
  Tab 2:
      Name (e.g. Home): Tasks
      SF Symbol [circle]: checklist
  Tab 3:
      Name (e.g. Home): Settings
      SF Symbol [circle]: gearshape
  👉 Add DevSettingsView (accessible from first tab toolbar in Dev/Mock builds)? [y/N]: n
  👉 Add onboarding flow (WelcomeView → OnboardingCompletedView)? [y/N]: y

  📦 Packages (NavigationKit always included):

     ▶ [x]  FulhamKit  (https://github.com/...)
     ↑↓ move   Space toggle   Enter confirm

  Output: ~/Developer (default — run 'boilerkit config' to change)

  ──────────────────────────────────────
  📋 Summary
  ──────────────────────────────────────
  App name:        MyApp
  Bundle ID:       com.acme.myapp
  Platforms:       iOS
  iOS target:      18.0
  Swift version:   6.0
  SwiftData:       yes
  First entity:    Task
  Localization:    en, pl, de
  SwiftLint:       yes
  SwiftFormat:     no
  DevSettings:     no
  Onboarding:      yes
  Tabs:
    - Home (house)
    - Tasks (checklist)
    - Settings (gearshape)
  Build configs:   Mock, Dev, Prod
  Team ID:         ABCD1234
  Packages:        NavigationKit
  Output:          /Users/you/Developer
  ──────────────────────────────────────

  👉 Generate project? [Y/n]: y

  🔨 Generating source files...
  ✅ Source files written
  🔨 Running XcodeGen...

  ──────────────────────────────────────
  ✅ MyApp is ready!
  ──────────────────────────────────────
  Open your project:
  open /Users/you/Developer/MyApp/MyApp.xcodeproj
```

---

## Generated project structure

The tree below shows a project named `MyApp` with 3 tabs, SwiftData (`Task` entity), localizations, and onboarding enabled. Optional sections are noted.

```
MyApp/
├── project.yml                         ← XcodeGen spec (can be re-run manually)
├── MyApp/
│   ├── Root/
│   │   ├── MyAppApp.swift              ← @main entry point
│   │   ├── AppDelegate.swift           ← UIApplicationDelegate, wires builders
│   │   ├── Dependencies.swift          ← build-config branching, DevPreview
│   │   ├── DependencyContainer.swift   ← @Observable service locator
│   │   ├── AppState.swift              ← (onboarding) @Observable showOnboarding flag
│   │   ├── AppViewBuilder.swift        ← (onboarding) animated main/onboarding switcher
│   │   ├── Localizable.xcstrings       ← (localization) String Catalog
│   │   ├── en.lproj/                   ← (localization) language region markers
│   │   ├── pl.lproj/
│   │   └── RIB/
│   │       ├── Builder.swift           ← @MainActor protocol Builder
│   │       ├── CoreBuilder.swift       ← tab bar + feature view wiring
│   │       ├── CoreInteractor.swift    ← root interactor
│   │       └── CoreRouter.swift        ← root router wrapping NavigationKit.Router
│   ├── Core/
│   │   ├── Onboarding/                 ← (onboarding)
│   │   │   ├── OnboardingBuilder.swift
│   │   │   ├── OnboardingInteractor.swift
│   │   │   ├── OnboardingRouter.swift
│   │   │   ├── Welcome/
│   │   │   │   ├── WelcomeView.swift
│   │   │   │   └── WelcomePresenter.swift
│   │   │   └── Completed/
│   │   │       ├── OnboardingCompletedView.swift
│   │   │       └── OnboardingCompletedPresenter.swift
│   │   ├── TabBar/
│   │   │   └── TabBarView.swift        ← data-driven TabView
│   │   ├── Home/
│   │   │   └── HomeView.swift          ← full RIB slice: protocol + Presenter + View
│   │   ├── Tasks/
│   │   │   └── TasksView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── Components/
│   │   ├── Extensions/
│   │   ├── ViewModifiers/
│   │   └── Views/
│   ├── Models/
│   │   ├── Domain/
│   │   │   └── Task.swift              ← (SwiftData) plain struct, Identifiable + Equatable
│   │   ├── Entities/
│   │   │   └── TaskEntity.swift        ← (SwiftData) @Model class
│   │   └── Services/
│   │       ├── TaskMapper.swift
│   │       ├── TaskRepository.swift    ← (SwiftData) protocol + Mock + SwiftData implementations
│   │       └── TaskManager.swift
│   └── Assets.xcassets/
├── MyAppTests/
│   ├── Shared/
│   │   └── Mocks/
│   └── Tags.swift                      ← Swift Testing tag definitions
└── MyApp.xcodeproj
```

---

## Architecture

Every generated project follows a VIPER/RIBs pattern. Each tab is a self-contained feature slice.

### Feature slice anatomy

Each tab generates a single `<Tab>View.swift` file containing four things:

```swift
// 1. Interactor protocol — what this feature can do with data
protocol HomeInteractor: AnyObject { }
extension CoreInteractor: HomeInteractor { }

// 2. Router protocol — navigation actions available from this feature
protocol HomeRouter: AnyObject {
    func dismissScreen()
}
extension CoreRouter: HomeRouter { }

// 3. Presenter — bridges interactor + router to the View
@Observable @MainActor
final class HomePresenter {
    private let interactor: any HomeInteractor
    private let router: any HomeRouter

    init(interactor: any HomeInteractor, router: any HomeRouter) {
        self.interactor = interactor
        self.router = router
    }
}

// 4. View — owns its Presenter, drives UI
struct HomeView: View {
    @State private var presenter: HomePresenter

    var body: some View {
        Text("Home")
    }
}
```

### CoreRouter

`CoreRouter` wraps `NavigationKit.Router` and exposes the full navigation surface:

```swift
func dismissScreen()    // dismiss/pop current screen
func popToRoot()        // clear current navigation stack
func dismissToRoot()    // tear down entire navigation hierarchy
func dismissModal()     // dismiss custom modal overlay
func dismissAlert()     // dismiss alert or confirmation dialog
```

Feature router protocols are extended onto `CoreRouter`:

```swift
protocol HomeRouter: AnyObject {
    func dismissScreen()
    func showDetail()       // your custom navigation actions
}

extension CoreRouter: HomeRouter {
    func showDetail() {
        router.showScreen(.push) { _ in DetailView() }
    }
}
```

### DependencyContainer

Services are registered and resolved by type via a string-keyed `@Observable` container:

```swift
// Register (in Dependencies.init)
container.register(TaskManager(repository: SwiftDataTaskRepository(container: modelContainer)))

// Resolve (in any Presenter)
let manager: TaskManager = container.resolve()
```

### Build configurations

| Config | Type | Scheme | Compiler flag | Bundle ID suffix | Display name |
|---|---|---|---|---|---|
| Mock | debug | `MyApp - Mock` | `MOCK` | `.mock` | `MyApp - Mock` |
| Debug | debug | `MyApp - Dev` | `DEV` | `.dev` | `MyApp - Dev` |
| Release | release | `MyApp - Prod` | _(none)_ | _(none)_ | `MyApp` |

Use compile-time branching to swap implementations:

```swift
// Generated in AppDelegate.swift
#if MOCK
    let dependencies = Dependencies(config: .mock)
#elseif DEV
    let dependencies = Dependencies(config: .dev)
#else
    let dependencies = Dependencies(config: .prod)
#endif
```

---

## SwiftData

When SwiftData is enabled and an entity name is provided, boilerkit generates a full persistence stack using the repository pattern:

```
Task            ← Domain model (plain struct, Identifiable + Equatable)
TaskEntity      ← SwiftData @Model class
TaskMapper      ← Converts between Task ↔ TaskEntity
TaskRepository  ← Protocol with fetchAll / save / delete
  MockTaskRepository       ← In-memory array (used in Mock scheme)
  SwiftDataTaskRepository  ← Real ModelContainer (used in Dev + Prod)
TaskManager     ← Delegates all operations to any TaskRepository
```

Register in `Dependencies.swift`:

```swift
// Mock scheme
container.register(TaskManager(repository: MockTaskRepository()))

// Dev / Prod
let modelContainer = try ModelContainer(for: TaskEntity.self)
container.register(TaskManager(repository: SwiftDataTaskRepository(container: modelContainer)))
```

---

## Onboarding

When onboarding is enabled, boilerkit generates a two-screen onboarding flow wired into the app's root navigation using the same RIBs pattern as the rest of the project.

### How it works

`AppState` holds a single `showOnboarding: Bool` flag that is persisted to `UserDefaults`. It defaults to `true` on the very first launch (key absent) and is set to `false` when the user taps **Finish** on the completion screen. From that point on, the app launches directly into the main tab bar.

`AppViewBuilder` is a generic SwiftUI view that switches between the onboarding and main experiences with a smooth animated transition:

```swift
AppViewBuilder(
    showOnboarding: delegate.appState.showOnboarding,
    mainView: { delegate.builder.build() },
    onboardingView: { delegate.onboardingBuilder.build() }
)
```

### Generated screens

| Screen | File | Description |
|---|---|---|
| Welcome | `Core/Onboarding/Welcome/WelcomeView.swift` | Entry screen with a "Get started" button |
| Completed | `Core/Onboarding/Completed/OnboardingCompletedView.swift` | Completion screen; "Finish" sets `showOnboarding = false` |

### Re-showing onboarding

To show onboarding again (e.g. after sign-out), call:

```swift
appState.updateViewState(showOnboarding: true)
```

---

## Localizations

When localizations are enabled, boilerkit generates:

- `Localizable.xcstrings` — a String Catalog seeded with an `app_name` key. English is pre-translated to your app name; all other languages are marked `needs_review` and ready to fill in.
- One `<lang>.lproj/` directory per language — these register the languages in Xcode's known regions so the catalog editor shows all selected languages immediately.

The following build settings are applied automatically:

```
LOCALIZATION_PREFERS_STRING_CATALOGS = YES   ← opts into the String Catalog workflow
SWIFT_EMIT_LOC_STRINGS = YES                 ← enables Swift symbol generation from the catalog
```

Add new keys directly in Xcode's String Catalog editor, or by calling `String(localized:)` in your code — Xcode will extract them automatically on build.

---

## Defaults

boilerkit saves defaults to `~/.boilerkit/config.json` to speed up repeated use. When a default is set, the wizard skips that question entirely and shows the stored value inline.

```sh
# Set once, skip forever
boilerkit config --output ~/Developer --team-id ABCD1234
```

At the end of each wizard run, boilerkit offers to save any new values (Team ID, output directory) that were typed during that session — but only those, not values that were already defaulted.

```
Save output directory and Team ID as defaults for future projects? [Y/n]:
```
