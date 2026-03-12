import Foundation

// MARK: - Wizard

struct Wizard {

    // MARK: - Run

    mutating func run() -> ProjectConfig {
        printBanner()

        let storedConfig = ConfigStore.load()

        let appName = askAppName()
        let bundleID = askBundleID(appName: appName)
        let teamID = askTeamID(stored: storedConfig.defaultTeamID)
        let platforms = askPlatforms()
        let deploymentTargets = askDeploymentTargets(for: platforms)
        let swiftVersion = askSwiftVersion()
        let (useSwiftData, entityName) = askSwiftData()
        let (useLocalization, localizationLanguages) = askLocalization()
        let (useLinting, useFormatting) = askCodeQualityTools()
        let tabs = askTabs()
        let useDevSettings = askDevSettings()
        let useOnboarding = askOnboarding()
        let packages = askPackages(stored: storedConfig.defaultPackages)
        let outputDirectory = askOutputDirectory(stored: storedConfig.defaultOutputDirectory)

        let config = ProjectConfig(
            appName: appName,
            bundleID: bundleID,
            platforms: platforms,
            deploymentTargets: deploymentTargets,
            swiftVersion: swiftVersion,
            useSwiftData: useSwiftData,
            swiftDataEntityName: entityName,
            tabs: tabs,
            teamID: teamID,
            packages: packages,
            outputDirectory: outputDirectory,
            useLocalization: useLocalization,
            localizationLanguages: localizationLanguages,
            useLinting: useLinting,
            useFormatting: useFormatting,
            useDevSettings: useDevSettings,
            useOnboarding: useOnboarding
        )

        printSummary(config)
        confirmGeneration()
        offerSaveDefaults(config: config, stored: storedConfig)

        return config
    }

    // MARK: - Banner

    private func printBanner() {
        print("")
        print("  🏗️  boilerkit")
        print("  iOS app project generator")
        print("  ──────────────────────────────────────")
        print("")
    }

    // MARK: - App Name

    private mutating func askAppName() -> String {
        var input = ask("App name (e.g. MyApp, no spaces): ")

        while true {
            let trimmed = input.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                printError("App name cannot be empty.")
            } else if trimmed.contains(" ") {
                printError("App name cannot contain spaces. Use PascalCase (e.g. MyApp).")
            } else if trimmed.first?.isLetter != true {
                printError("App name must start with a letter.")
            } else {
                return trimmed
            }

            input = reask("App name (e.g. MyApp, no spaces): ")
        }
    }

    // MARK: - Bundle ID

    private mutating func askBundleID(appName: String) -> String {
        let defaultValue = "com.yourcompany.\(appName.lowercased())"
        let input = ask("Bundle ID [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - Platforms

    private mutating func askPlatforms() -> [Platform] {
        print("  Target platforms (iOS is always included):")
        print("    1. macOS")
        print("    2. watchOS")
        print("    3. tvOS")
        print("    4. visionOS")
        print("")

        let input = ask("Add platforms? Enter numbers separated by spaces, or press Enter to skip: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        var platforms: [Platform] = [.iOS]

        guard !trimmed.isEmpty else { return platforms }

        let choices = trimmed.split(separator: " ").compactMap { Int($0) }
        let optional: [Platform] = [.macOS, .watchOS, .tvOS, .visionOS]

        for choice in choices {
            guard choice >= 1, choice <= optional.count else {
                printWarning("Ignoring unknown platform option: \(choice)")
                continue
            }
            let platform = optional[choice - 1]
            if !platforms.contains(where: { $0.rawValue == platform.rawValue }) {
                platforms.append(platform)
            }
        }

        return platforms
    }

    // MARK: - Deployment Targets

    private mutating func askDeploymentTargets(for platforms: [Platform]) -> [Platform: String] {
        print("")
        print("  Deployment targets (press Enter to accept defaults):")

        var targets: [Platform: String] = [:]

        for platform in platforms {
            let defaultValue = platform.defaultDeploymentTarget
            let input = askSub("\(platform.rawValue) [\(defaultValue)]: ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)
            targets[platform] = trimmed.isEmpty ? defaultValue : trimmed
        }

        return targets
    }

    // MARK: - Swift Version

    private mutating func askSwiftVersion() -> String {
        let defaultValue = "6.0"
        let input = ask("Swift version [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - SwiftData

    private mutating func askSwiftData() -> (Bool, String?) {
        let useSwiftData = askYesNo("Use SwiftData for persistence?", default: true)

        guard useSwiftData else { return (false, nil) }

        let input = askSub("First entity name (e.g. Item), or press Enter to skip: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let entityName = trimmed.isEmpty ? nil : trimmed.capitalized

        return (true, entityName)
    }

    // MARK: - Localization

    private mutating func askLocalization() -> (Bool, [String]) {
        let useLocalization = askYesNo("Add localizations?", default: false)
        guard useLocalization else { return (false, []) }

        let available: [(code: String, label: String)] = [
            ("pl", "Polish"),
            ("de", "German"),
            ("fr", "French"),
            ("es", "Spanish"),
            ("it", "Italian"),
            ("pt", "Portuguese"),
            ("ja", "Japanese"),
            ("zh-Hans", "Chinese Simplified"),
            ("zh-Hant", "Chinese Traditional"),
            ("ar", "Arabic"),
            ("ru", "Russian"),
            ("ko", "Korean"),
        ]

        let result = selectMultiple(
            title: "  🌍 Languages (English is always included):",
            options: available.map { (name: $0.label, description: $0.code) },
            defaults: Array(repeating: false, count: available.count)
        )

        let languages = zip(available, result)
            .filter { $0.1 }
            .map { $0.0.code }

        return (true, languages)
    }

    // MARK: - Code Quality Tools

    private mutating func askCodeQualityTools() -> (useLinting: Bool, useFormatting: Bool) {
        let result = selectMultiple(
            title: "  👉 Code quality tools:",
            options: [
                (name: "SwiftLint",   description: "linting"),
                (name: "SwiftFormat", description: "formatting"),
            ],
            defaults: [true, false] // SwiftLint on by default, SwiftFormat off
        )

        return (useLinting: result[0], useFormatting: result[1])
    }

    // MARK: - Tabs

    private mutating func askTabs() -> [Tab] {
        var count: Int = 0

        var input = ask("Number of tabs (1–6): ")
        while true {
            let trimmed = input.trimmingCharacters(in: .whitespaces)
            if let value = Int(trimmed), value >= 1, value <= 6 {
                count = value
                break
            }
            printError("Please enter a number between 1 and 6.")
            input = reask("Number of tabs (1–6): ")
        }

        print("")

        // Single-tab: no Tab Bar is created — ask only for the root view name.
        if count == 1 {
            print("  No Tab Bar will be created. Name your root view:")
            let name = askTabName()
            return [Tab(name: name, sfSymbol: "circle")]
        }

        print("  Configure each tab (name + SF Symbol):")

        var tabs: [Tab] = []

        for i in 1...count {
            print("  Tab \(i):")
            let name = askTabName()
            let symbol = askSFSymbol()
            tabs.append(Tab(name: name, sfSymbol: symbol))
        }

        return tabs
    }

    private func askTabName() -> String {
        while true {
            let input = askSub("    Name (e.g. Home): ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else {
                printError("Tab name cannot be empty.")
                continue
            }

            guard !trimmed.contains(" ") else {
                printError("Tab name cannot contain spaces.")
                continue
            }

            return trimmed
        }
    }

    private func askSFSymbol() -> String {
        let defaultValue = "circle"
        let input = askSub("    SF Symbol [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - Dev Settings

    private mutating func askDevSettings() -> Bool {
        askYesNo("Add DevSettingsView (accessible from first tab toolbar in DEBUG builds)?", default: false)
    }

    // MARK: - Onboarding

    private mutating func askOnboarding() -> Bool {
        askYesNo("Add onboarding flow (WelcomeView → OnboardingCompletedView)?", default: false)
    }

    // MARK: - Packages

    private static let navigationKit = SwiftPackage(
        name: "NavigationKit",
        url: "https://github.com/KociucKy/NavigationKit",
        branch: "master"
    )

    private mutating func askPackages(stored: [SwiftPackage]) -> [SwiftPackage] {
        // Build the display list: NavigationKit is always first and pinned selected.
        // Saved packages follow, all pre-selected.
        let savedPackages = stored.filter { $0.name != Self.navigationKit.name }
        let displayList = savedPackages  // NavigationKit shown separately as pinned
        var selected = Array(repeating: true, count: displayList.count)

        if displayList.isEmpty {
            // No saved packages — just show NavigationKit as pinned and skip selection UI
            print("")
            print("  [x] NavigationKit (always included)")
        } else {
            print("")
            print("  Packages ([x] = included):")
            print("     [x] NavigationKit  (always included)")

            while true {
                for (i, pkg) in displayList.enumerated() {
                    let mark = selected[i] ? "x" : " "
                    let index = String(format: "%2d", i + 1)
                    print("     [\(mark)] \(index). \(pkg.name)  \(pkg.url)  (\(pkg.branch))")
                }
                print("")
                let input = askSub("Toggle numbers to deselect (e.g. 1 2), or press Enter to confirm: ")
                let trimmed = input.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { break }

                let indices = trimmed.split(separator: " ").compactMap { Int($0) }
                for idx in indices {
                    guard idx >= 1, idx <= displayList.count else {
                        printWarning("Ignoring unknown package number: \(idx)")
                        continue
                    }
                    selected[idx - 1].toggle()
                }
                print("")
            }
        }

        var packages: [SwiftPackage] = [Self.navigationKit]
        for (i, pkg) in displayList.enumerated() where selected[i] {
            packages.append(pkg)
        }

        // Allow adding extra packages for this run
        print("")
        print("  Add more packages? Enter \"Name https://url branch\" or press Enter to skip.")
        while true {
            let input = askSub("  Package (or Enter to finish): ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { break }

            let parts = trimmed.split(separator: " ", maxSplits: 2).map(String.init)
            guard parts.count == 3 else {
                printError("Format must be: Name https://url branch")
                continue
            }
            packages.append(SwiftPackage(name: parts[0], url: parts[1], branch: parts[2]))
        }

        return packages
    }

    // MARK: - Team ID

    private mutating func askTeamID(stored: String?) -> String? {
        if let stored {
            print("  Team ID: \(stored) (default — run 'boilerkit config' to change)")
            return stored
        }

        let input = ask("Apple Team ID (press Enter to skip): ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Output Directory

    private mutating func askOutputDirectory(stored: String?) -> String {
        if let stored {
            print("  Output: \(stored) (default — run 'boilerkit config' to change)")
            return stored
        }

        let defaultValue = FileManager.default.currentDirectoryPath
        let input = ask("Output directory [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let raw = trimmed.isEmpty ? defaultValue : trimmed
        return (raw as NSString).expandingTildeInPath
    }

    // MARK: - Summary

    private func printSummary(_ config: ProjectConfig) {
        print("")
        print("  ──────────────────────────────────────")
        print("  📋 Summary")
        print("  ──────────────────────────────────────")
        print("  App name:        \(config.appName)")
        print("  Bundle ID:       \(config.bundleID)")
        print("  Platforms:       \(config.platforms.map(\.rawValue).joined(separator: ", "))")

        for platform in config.platforms {
            let target = config.deploymentTargets[platform] ?? platform.defaultDeploymentTarget
            print("  \(platform.rawValue) target:  \(target)")
        }

        print("  Swift version:   \(config.swiftVersion)")
        print("  SwiftData:       \(config.useSwiftData ? "yes" : "no")")

        if let entity = config.swiftDataEntityName {
            print("  First entity:    \(entity)")
        }

        if config.useLocalization {
            let langs = (["en"] + config.localizationLanguages).joined(separator: ", ")
            print("  Localization:    \(langs)")
        } else {
            print("  Localization:    none")
        }

        print("  SwiftLint:       \(config.useLinting ? "yes" : "no")")
        print("  SwiftFormat:     \(config.useFormatting ? "yes" : "no")")
        print("  DevSettings:     \(config.useDevSettings ? "yes" : "no")")
        print("  Onboarding:      \(config.useOnboarding ? "yes" : "no")")

        if config.tabs.count == 1, let tab = config.tabs.first {
            print("  Root view:       \(tab.sanitizedName) (no Tab Bar)")
        } else {
            print("  Tabs:")
            for tab in config.tabs {
                print("    - \(tab.sanitizedName) (\(tab.sfSymbol))")
            }
        }

        print("  Build configs:   Mock, Dev, Prod")
        print("  Team ID:         \(config.teamID ?? "none")")
        let packageNames = config.packages.map(\.name).joined(separator: ", ")
        print("  Packages:        \(packageNames)")
        print("  Output:          \(config.outputDirectory)")
        print("  ──────────────────────────────────────")
        print("")
    }

    // MARK: - Confirmation

    private mutating func confirmGeneration() {
        var input = ask("Generate project? [Y/n]: ")

        while true {
            let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

            if trimmed.isEmpty || trimmed == "y" || trimmed == "yes" {
                print("")
                return
            } else if trimmed == "n" || trimmed == "no" {
                print("")
                print("  Cancelled.")
                exit(0)
            } else {
                printError("Please enter Y or n.")
                input = reask("Generate project? [Y/n]: ")
            }
        }
    }

    // MARK: - Save Defaults

    private mutating func offerSaveDefaults(config: ProjectConfig, stored: BoilerkitConfig) {
        let shouldOfferOutput = stored.defaultOutputDirectory == nil
        let shouldOfferTeamID = stored.defaultTeamID == nil && config.teamID != nil

        // New packages: those in config but not already in stored defaults
        // (exclude NavigationKit since it's always pinned, not user-added)
        let storedPackageNames = Set(stored.defaultPackages.map(\.name))
        let newPackages = config.packages.filter {
            $0.name != Wizard.navigationKit.name && !storedPackageNames.contains($0.name)
        }
        let shouldOfferPackages = !newPackages.isEmpty

        guard shouldOfferOutput || shouldOfferTeamID || shouldOfferPackages else { return }

        var parts: [String] = []
        if shouldOfferOutput { parts.append("output directory") }
        if shouldOfferTeamID { parts.append("Team ID") }
        if shouldOfferPackages {
            let names = newPackages.map(\.name).joined(separator: ", ")
            parts.append("packages (\(names))")
        }
        let label = parts.joined(separator: ", ")

        let save = askYesNo("Save \(label) as defaults for future projects?", default: true)
        guard save else { return }

        ConfigStore.update { c in
            if shouldOfferOutput {
                c.defaultOutputDirectory = config.outputDirectory
            }
            if shouldOfferTeamID {
                c.defaultTeamID = config.teamID
            }
            if shouldOfferPackages {
                c.defaultPackages.append(contentsOf: newPackages)
            }
        }

        print("  ✅ Defaults saved. Run 'boilerkit config' to view or change them.")
        print("")
    }

    // MARK: - Helpers

    /// Finger-right prompt — used for each top-level wizard question.
    private mutating func ask(_ prompt: String) -> String {
        print("  👉 \(prompt)", terminator: "")
        guard let line = readLine() else { exit(0) }
        return line
    }

    /// Re-prompt after a validation error (same emoji, no side effects).
    private mutating func reask(_ prompt: String) -> String {
        print("  👉 \(prompt)", terminator: "")
        guard let line = readLine() else { exit(0) }
        return line
    }

    /// Yes/no prompt — delegates to ask().
    private mutating func askYesNo(_ prompt: String, default defaultValue: Bool) -> Bool {
        let hint = defaultValue ? "[Y/n]" : "[y/N]"
        let input = ask("\(prompt) \(hint): ")
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed.isEmpty { return defaultValue }
        return trimmed == "y" || trimmed == "yes"
    }

    /// Sub-prompt for follow-up inputs within the same question
    /// (deployment targets per platform, tab name/symbol, entity name).
    private func askSub(_ prompt: String) -> String {
        print("     \(prompt)", terminator: "")
        guard let line = readLine() else { exit(0) }
        return line
    }

    private func printError(_ message: String) {
        print("  ⚠️  \(message)")
    }

    private func printWarning(_ message: String) {
        print("  ⚠️  \(message)")
    }
}
