# boilerkit — Project Plan

## Overview

A Swift CLI tool that interactively generates a fully-wired Xcode project following the VIPER/RIBs architecture defined in `copilot-instructions.md`. Run via `swift run boilerkit` from this repo.

## Repo Structure

```
boilerkit/
├── Package.swift
├── PLAN.md
├── copilot-instructions.md
└── Sources/
    └── boilerkit/
        ├── main.swift
        ├── Wizard.swift
        ├── ProjectConfig.swift
        ├── FileGenerator.swift
        ├── XcodeGenRunner.swift
        └── Templates/
            ├── AppTemplate.swift
            ├── AppDelegateTemplate.swift
            ├── DependenciesTemplate.swift
            ├── DependencyContainerTemplate.swift
            ├── CoreBuilderTemplate.swift
            ├── CoreInteractorTemplate.swift
            ├── CoreRouterTemplate.swift
            ├── TabBarTemplate.swift
            ├── FeatureViewTemplate.swift
            └── SwiftDataTemplates.swift
```

## Wizard Questions

1. App name
2. Bundle ID (default: `com.yourcompany.<appname>`)
3. Target platforms (iOS always on; optional: macOS, watchOS, tvOS, visionOS)
4. Deployment targets per platform (defaults: iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2)
5. Swift version (default: `6.0`)
6. SwiftData — yes/no; if yes, optional first entity name
7. Tabs — count (1–6) + name + SF Symbol per tab
8. Build configurations — fixed: Mock/Dev/Prod (no choice, just inform)
9. Team ID — optional (empty = manual signing)
10. NavigationKit SPM URL — overridable (default placeholder)
11. Output directory — default: current working directory
12. Confirmation summary — show all choices, ask "Generate? [Y/n]"

## What Gets Generated

### Root/
- `<AppName>App.swift` — `@main` App struct
- `AppDelegate.swift` — UIApplicationDelegate, constructs Dependencies
- `Dependencies.swift` — Dependencies struct + BuildConfiguration enum
- `DependencyContainer.swift` — register/resolve DI container

### Root/RIB/
- `CoreBuilder.swift` — wires Presenter ↔ Interactor ↔ Router, returns TabBarView
- `CoreInteractor.swift` — conforms to all `<Feature>Interactor` protocols
- `CoreRouter.swift` — wraps NavigationKit.Router, conforms to all `<Feature>Router` protocols

### Core/TabBar/
- `TabBarView.swift` — SwiftUI TabView with configured tabs

### Core/<TabName>/ (one per tab)
- `<TabName>View.swift` — View + Presenter + protocol stubs for Interactor/Router

### Models/ (if SwiftData enabled)
- `Domain/<EntityName>.swift` — plain Swift struct
- `Entities/<EntityName>Entity.swift` — `@Model` class
- `Services/<EntityName>Mapper.swift` — entity ↔ domain mapper
- `Services/<EntityName>Repository.swift` — protocol + SwiftData + Mock implementations
- `Services/<EntityName>Manager.swift` — uses repository, registered in DI container

### Project Files
- `project.yml` — XcodeGen manifest: targets, platforms, deployment targets, build configs, SPM deps, signing
- `Assets.xcassets` — AppIcon + AccentColor placeholders

### Tests/
- `<AppName>Tests/Tags.swift` — shared Tag extensions
- `<AppName>Tests/Shared/` — placeholder for shared mocks

## Build Configurations

Always three: **Mock**, **Dev**, **Prod**

Compiler flags: `-D MOCK`, `-D DEV` (Prod has none)

## External Dependencies

- **swift-argument-parser** — CLI entry point
- **XcodeGen** (external, via Homebrew) — project generation; graceful error if not installed

## Architecture Rules (from copilot-instructions.md)

All generated code must follow:
- `@Observable @MainActor` Presenters
- Per-feature protocol definitions in the same file as View/Presenter
- `CoreInteractor`/`CoreRouter` conforming via `extension`
- `#Preview` macros with `RouterView` scoping
- Swift Testing for test scaffolding (never XCTest)
- No `@StateObject`, `@ObservedObject`, `@Published`, `ObservableObject`
- iOS 18 minimum, Swift 6.0+

## Implementation Order

1. `Package.swift` — Swift package manifest
2. `ProjectConfig.swift` — data model for all wizard answers
3. `Wizard.swift` — interactive prompt loop
4. Templates — one per generated file type
5. `FileGenerator.swift` — token substitution + file writing
6. `XcodeGenRunner.swift` — builds `project.yml`, shells out to xcodegen
7. `main.swift` — orchestrates wizard → generator → runner
8. End-to-end test with a sample app
