# boilerkit

A Swift CLI tool that interactively scaffolds a production-ready Xcode project following a strict VIPER/RIBs architecture. Answer a few questions and get a fully-wired `.xcodeproj` — complete with build configurations, schemes, SwiftData persistence, localizations, and a tab-based navigation shell — ready to open and run.

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

Running `boilerkit` starts an interactive prompt. Each question is numbered. Sub-prompts (deployment targets, tab details, language selection) are indented continuations of their parent step — they don't get their own number.

### Full example session

```
  🏗️  boilerkit
  iOS app project generator
  ──────────────────────────────────────

  1. App name (e.g. MyApp, no spaces): MyApp
  2. Bundle ID [com.yourcompany.myapp]: com.acme.myapp
  Team ID: ABCD1234 (default — run 'boilerkit config' to change)
  3. Target platforms (iOS is always included):
       1. macOS
       2. watchOS
       3. tvOS
       4. visionOS

     Add platforms? Enter numbers separated by spaces, or press Enter to skip:
  3. Deployment targets (press Enter to accept defaults):
     iOS [18.0]:
  4. Swift version [6.0]:
  5. Use SwiftData for persistence? [Y/n]: y
     First entity name (e.g. Item), or press Enter to skip: Task
  6. Add localizations? [y/N]: y

     Available languages (English is always included):
      1. Polish (pl)
      2. German (de)
      3. French (fr)
      4. Spanish (es)
      5. Italian (it)
      6. Portuguese (pt)
      7. Japanese (ja)
      8. Chinese Simplified (zh-Hans)
      9. Chinese Traditional (zh-Hant)
     10. Arabic (ar)
     11. Russian (ru)
     12. Korean (ko)

     Enter numbers separated by spaces, or press Enter to skip: 1 2
  7. Number of tabs (1–6): 3

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
  8. NavigationKit SPM URL [https://github.com/KociucKy/NavigationKit]:
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
  Tabs:
    - Home (house)
    - Tasks (checklist)
    - Settings (gearshape)
  Build configs:   Mock, Dev, Prod
  Team ID:         ABCD1234
  NavigationKit:   https://github.com/KociucKy/NavigationKit
  Output:          /Users/you/Developer
  ──────────────────────────────────────

  9. Generate project? [Y/n]: y

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

```
MyApp/
├── project.yml                         ← XcodeGen spec (can be re-run manually)
├── MyApp/
│   ├── Root/
│   │   ├── MyAppApp.swift              ← @main entry point
│   │   ├── AppDelegate.swift           ← UIApplicationDelegate, wires Dependencies + CoreBuilder
│   │   ├── Dependencies.swift          ← build-config branching, DevPreview
│   │   ├── DependencyContainer.swift   ← @Observable service locator
│   │   ├── Localizable.xcstrings       ← String Catalog (if localizations enabled)
│   │   ├── en.lproj/                   ← language region markers (one per language)
│   │   ├── pl.lproj/
│   │   └── RIB/
│   │       ├── Builder.swift           ← @MainActor protocol Builder
│   │       ├── CoreBuilder.swift       ← tab bar + feature view wiring
│   │       ├── CoreInteractor.swift    ← root interactor
│   │       └── CoreRouter.swift        ← root router wrapping NavigationKit.Router
│   ├── Core/
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
│   │   │   └── Task.swift              ← plain struct (if SwiftData enabled)
│   │   ├── Entities/
│   │   │   └── TaskEntity.swift        ← @Model class
│   │   └── Services/
│   │       ├── TaskMapper.swift
│   │       ├── TaskRepository.swift    ← protocol + Mock + SwiftData implementations
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

| Config | Type | Scheme | Compiler flag | Bundle ID suffix |
|---|---|---|---|---|
| Mock | debug | `MyApp - Mock` | `MOCK` | `.mock` |
| Debug | debug | `MyApp - Dev` | `DEV` | `.dev` |
| Release | release | `MyApp - Prod` | _(none)_ | _(none)_ |

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
