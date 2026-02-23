# iOS App Coding Instructions for GitHub Copilot

## 1. Architecture (VIPER-inspired / RIB-style)

### Layer Responsibilities
- **View**: SwiftUI views. Declare UI only; delegate all actions to Presenter.
- **Presenter**: `@Observable @MainActor` classes holding view state. Call Interactor for business logic and Router for navigation.
- **Interactor**: Lightweight façade exposing sync throwing methods that delegate to domain Managers.
- **Router**: Wraps `NavigationKit.Router` for navigation (push, sheet, fullScreenCover, alerts).
- **Builder**: Factory struct that wires Presenter ↔ Interactor ↔ Router and returns Views.

### Protocols per Feature
Each feature defines its own protocols in the same file as the View/Presenter:
```swift
@MainActor
protocol <Feature>Interactor {
    func someAction() throws
}

extension CoreInteractor: <Feature>Interactor {}

@MainActor
protocol <Feature>Router {
    func navigateSomewhere()
}

extension CoreRouter: <Feature>Router {}
```

## 2. State Management

- Use `@Observable` (Observation framework) for Presenters and reference-type state holders.
- Use `@State` **only** for purely view-local, ephemeral state.
- Use `@Binding` sparingly – prefer passing closures or Presenter bindings.
- **Do NOT use**: `@StateObject`, `@ObservedObject`, `@Published`, `ObservableObject`, `@EnvironmentObject`.

## 3. Concurrency & Main Actor

- Annotate all Presenters, Interactors, Routers, Builders, and UI-related code with `@MainActor`.
- Use Swift Concurrency (`async`/`await`, `TaskGroup`) for asynchronous work.
- Avoid naming any type `Task` to prevent shadowing Swift Concurrency's `Task`.

## 4. Navigation (NavigationKit)

- Import `NavigationKit` and use `RouterView { router in … }` to scope navigation.
- Router wrapper exposes methods like:
  - `showScreen(.push / .sheet / .fullScreenCover) { router in builder.someView(router:) }`
  - `dismissScreen()`, `dismissModal()`, `showAlert(…)`, `showConfirmationDialog(…)`
- Add new routes by:
  1. Adding a builder method in the Builder.
  2. Adding a corresponding `show…` method in the Router.

## 5. Dependency Injection

- Use a `DependencyContainer` (simple register/resolve pattern) for service registration.
- Construct `Dependencies` in `AppDelegate`, passing `BuildConfiguration` (`.mock`, `.dev`, `.prod`).
- Interactor resolves managers from the container at init.
- For SwiftUI Previews, use a shared preview container with mock repositories.

## 6. Persistence & Domain Models

- **Domain models** (structs) live in `Models/Domain/` – pure Swift, no SwiftData annotations.
- **SwiftData entities** live in `Models/Entities/` – `@Model` classes for persistence.
- Mappers (`*EntityMapper`) convert between entities and domain models.
- Repositories (`*Repository` protocols) abstract data access; implementations:
  - `SwiftData*Repository` for real persistence.
  - `Mock*Repository` for previews/tests.
- Managers use repositories + mappers and are registered in `DependencyContainer`.

## 7. Folder Structure

```
<AppName>/
├── Root/                    # App entry, DI, RIB core
│   ├── <AppName>App.swift
│   ├── AppDelegate.swift
│   ├── Dependencies.swift
│   ├── DependencyContainer.swift
│   └── RIB/
│       ├── Builder.swift
│       ├── CoreBuilder.swift
│       ├── CoreInteractor.swift
│       └── CoreRouter.swift
├── Core/                    # Feature modules (screens)
│   ├── <Feature>/
│   │   ├── <Feature>View.swift
│   │   └── Components/      # Feature-specific subviews
│   └── TabBar/
├── Components/              # Reusable UI
│   ├── Extensions/
│   ├── ViewModifiers/
│   └── Views/
├── Models/
│   ├── Domain/              # Domain structs
│   ├── Entities/            # SwiftData @Model classes
│   └── Services/            # Managers, Repositories, Mappers
└── Assets.xcassets/
```

## 8. SwiftUI Conventions

### Layout
- Prefer `Form`, `List`, `Section` for settings/form UIs.
- Use `LazyVStack`, `LazyHGrid` for large collections.
- Use `Grid` for complex layouts; `ViewThatFits` for adaptive interfaces.
- Apply `.contentMargins()`, `.containerRelativeFrame()` for spacing/sizing.

### Components
- Use `ScrollView` with `.scrollTargetBehavior()` for paging/snapping.
- Leverage SF Symbols with `.symbolEffect()` for animations.
- Extract reusable styles into custom `ViewModifier`s.

### Animation & Interaction
- Use `.animation(_:value:)` for state-driven animations.
- Use `.sensoryFeedback()` for haptics.
- Use SwiftUI gestures (`TapGesture`, `LongPressGesture`, etc.).

## 9. Accessibility

- Every interactive element must have `.accessibilityLabel()` and `.accessibilityHint()`.
- Use `.accessibilityElement(children:)` to group/customize VoiceOver focus.
- Support Dynamic Type; test with larger text sizes.
- Respect reduced-motion settings.

## 10. Naming & Style

- Protocols: `<Feature>Interactor`, `<Feature>Router`.
- Presenters: `<Feature>Presenter` (class, `@Observable @MainActor`).
- Views: `<Feature>View` (struct).
- Props structs: `<Feature>ViewProps` when extra configuration is passed to View.
- Use `// MARK: -` to organize Properties, Init, Methods sections.
- Keep files focused; one Presenter + one View per file is acceptable.

## 11. Error Handling

- Interactor/Manager methods throw; Presenters catch and log/display errors.
- Use `do/catch` in Presenter action methods.

## 12. Previews

- Use `#Preview` macro.
- Construct a preview container → Builder → builder method.
- Wrap in `RouterView { router in … }` to enable navigation in previews.

## 13. Build Configurations

- Three schemes: `Mock`, `Dev`, `Prod`.
- Conditional compilation: `#if MOCK`, `#if DEV`, `#else` (Prod).
- Mock config uses `Mock*Repository`; Dev/Prod use `SwiftData*Repository`.

## 14. SDK, Deployment Target & Availability

- Swift 6.0+, latest SwiftUI.
- **Minimum deployment target: iOS 18.**
- Use SwiftData for persistence.
- Use Swift Concurrency for networking.

### Availability Checks
When using APIs introduced after iOS 18, wrap them with `#available` or `@available`:

```swift
// Runtime check
if #available(iOS 26, *) {
    // Use iOS 26+ API
} else {
    // Fallback for iOS 18
}

// Mark entire function/type
@available(iOS 26, *)
func newFeature() { }

// Compile-time check (Swift version)
#if swift(>=6.1)
// Code requiring Swift 6.1+
#endif
```

Always prefer `#available` for OS version checks and `#if swift(...)` for Swift language features.

## 15. Unit Testing (Swift Testing)

- Use **Swift Testing** framework (`import Testing`) – do NOT use XCTest for new tests.
- Organize tests using `@Suite` for grouping related tests.
- Use `@Test` macro for individual test functions.
- Apply `Tag` to categorize tests by feature and behavior.
- Always use **mock objects** (from `Mock*Repository` or custom mocks) – never hit real services/persistence.
- Structure every test with comments: `// Arrange`, `// Act`, `// Assert`.
- Use descriptive test names that explain the scenario and expected outcome.
- Leverage parameterized tests with `@Test(arguments:)` for testing multiple inputs.

### Test Folder Structure

```
<AppName>Tests/
├── <Feature>/
│   ├── <Feature>PresenterTests.swift
│   └── Mocks/
│       ├── Mock<Feature>Interactor.swift
│       └── Mock<Feature>Router.swift
└── Shared/
    └── Mocks/                   # Shared mocks across features
```

### Mock Structure

Mocks should follow a consistent pattern with properties grouped above their corresponding methods:

```swift
@MainActor
final class MockFeatureInteractor: FeatureInteractor {
    
    // MARK: - someMethod
    
    var someMethodCalled = false
    var someMethodCallsCount = 0
    var someMethodReceivedArgument: String?
    var someMethodShouldThrowError = false
    
    func someMethod(argument: String) throws {
        if someMethodShouldThrowError {
            throw NSError(domain: "Test", code: 1)
        }
        someMethodCalled = true
        someMethodCallsCount += 1
        someMethodReceivedArgument = argument
    }
    
    // MARK: - anotherMethod
    
    var anotherMethodCalled = false
    var anotherMethodCallsCount = 0
    
    func anotherMethod() {
        anotherMethodCalled = true
        anotherMethodCallsCount += 1
    }
}
```

**Mock Property Naming Convention:**
- `<methodName>Called: Bool` – whether the method was called at least once
- `<methodName>CallsCount: Int` – how many times the method was called
- `<methodName>ReceivedArgument: <Type>?` – the last argument passed (for single param)
- `<methodName>ReceivedArguments: (<Type>, <Type>)?` – tuple of last arguments (for multiple params)
- `<methodName>ShouldThrowError: Bool` – controls whether the method throws
- `<methodName>ReturnValue: <Type>` – the value to return (for non-void methods)

### Tags

Define feature-specific and behavior-specific tags for filtering tests:

```swift
extension Tag {
    // Feature tags
    @Tag static var taskForm: Self
    @Tag static var routines: Self
    @Tag static var sessions: Self
    
    // Behavior tags
    @Tag static var adding: Self
    @Tag static var deleting: Self
    @Tag static var editing: Self
    @Tag static var navigation: Self
    
    // Priority tags
    @Tag static var critical: Self
    @Tag static var slow: Self
}
```

### Example Test Structure

```swift
import Testing
import SwiftUI
@testable import <AppName>

// MARK: - Tags

extension Tag {
    @Tag static var taskForm: Self
    @Tag static var addSubtask: Self
    @Tag static var deleteSubtask: Self
}

// MARK: - Mocks

@MainActor
final class MockTaskFormInteractor: TaskFormInteractor {
    
    // MARK: - addRoutine
    
    var addRoutineCalled = false
    var addRoutineCallsCount = 0
    var addedRoutine: Routine?
    var addRoutineShouldThrowError = false
    
    func addRoutine(_ routine: Routine) throws {
        if addRoutineShouldThrowError {
            throw NSError(domain: "Test", code: 1)
        }
        addRoutineCalled = true
        addRoutineCallsCount += 1
        addedRoutine = routine
    }
    
    // MARK: - updateRoutine
    
    var updateRoutineCalled = false
    var updateRoutineCallsCount = 0
    var updatedRoutine: Routine?
    
    func updateRoutine(_ routine: Routine) throws {
        updateRoutineCalled = true
        updateRoutineCallsCount += 1
        updatedRoutine = routine
    }
}

@MainActor
final class MockTaskFormRouter: TaskFormRouter {
    
    // MARK: - dismissScreen
    
    var dismissScreenCalled = false
    var dismissScreenCallsCount = 0
    
    func dismissScreen() {
        dismissScreenCalled = true
        dismissScreenCallsCount += 1
    }
}

// MARK: - Test Suite

@Suite("TaskFormPresenter Tests", .tags(.taskForm))
@MainActor
struct TaskFormPresenterTests {
    
    // MARK: - Properties
    
    let interactor = MockTaskFormInteractor()
    let router = MockTaskFormRouter()
    
    // MARK: - Add Subtask Tests
    
    @Test("Adding subtask with valid name appends to list", .tags(.addSubtask))
    func addSubtask_withValidName_appendsToList() {
        // Arrange
        let sut = TaskFormPresenter(
            interactor: interactor,
            router: router,
            routine: nil,
            formState: .adding
        )
        sut.newSubtaskName = "Test Subtask"
        sut.newPlanned = 600
        
        // Act
        sut.onAddSubtask()
        
        // Assert
        #expect(sut.subtasks.count == 1)
        #expect(sut.subtasks[0].name == "Test Subtask")
        #expect(interactor.addRoutineCallsCount == 0)
        #expect(interactor.updateRoutineCallsCount == 0)
        #expect(router.dismissScreenCallsCount == 0)
    }
    
    @Test("Deleting subtask in editing mode calls update", .tags(.deleteSubtask))
    func deleteSubtask_inEditingMode_callsUpdate() {
        // Arrange
        let routine = Routine(/* ... */)
        let sut = TaskFormPresenter(
            interactor: interactor,
            router: router,
            routine: routine,
            formState: .editing
        )
        let subtask = SubTask(id: UUID(), sortIndex: 0, name: "Test", plannedDuration: 300, averageDuration: 300)
        sut.subtasks = [subtask]
        
        // Act
        sut.onDeleteSubtasks(task: subtask)
        
        // Assert
        #expect(interactor.updateRoutineCalled == true)
        #expect(interactor.updateRoutineCallsCount == 1)
        #expect(interactor.addRoutineCallsCount == 0)
        #expect(router.dismissScreenCallsCount == 0)
    }
}
```

### Test Naming Convention

Use the pattern: `methodName_scenario_expectedBehavior`

Examples:
- `addSubtask_withValidName_appendsToList`
- `addSubtask_withEmptyName_doesNothing`
- `deleteSubtask_inEditingMode_callsUpdate`
- `updateRoutine_withoutRoutine_doesNothing`

### Best Practices

- **Test one behavior per test function.**
- **Use `#expect()` for assertions** (not XCTAssert).
- **Use `#require()` for preconditions** that must pass for the test to continue.
- **Mock all external dependencies** (repositories, network, interactors, routers).
- **Keep tests fast** – avoid async waits when possible.
- **Use `@Suite` to share setup logic** via init or stored properties.
- **Always verify CallsCount** – ensure methods are called the expected number of times.
- **Verify negative cases** – check that unrelated methods are NOT called (e.g., `addRoutineCallsCount == 0` when testing update).
- **Group related mock properties** – place `Called`, `CallsCount`, `ReceivedArgument`, `ShouldThrowError` directly above the method they track.
- **Use `// MARK: -`** to separate mock method groups and test categories.
- **Apply tags consistently** – tag tests with both feature tag and behavior tag when applicable.

## 16. Forbidden Patterns

- Do NOT use SPM modules/frameworks to organize internal code – all source lives in the main app target.
- Do NOT use `@_exported import` or `@_implementationOnly import`.
- Do NOT use `Task` as a type name.
- Do NOT use deprecated state management: `@StateObject`, `@ObservedObject`, `@Published`, `ObservableObject`, `@EnvironmentObject`.
- Do NOT use XCTest for new unit tests – use Swift Testing instead.
