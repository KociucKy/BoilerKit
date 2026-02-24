import Foundation

// MARK: - Wizard

struct Wizard {

    // MARK: - State

    private var step = 0

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
        let tabs = askTabs()
        let navigationKitURL = askNavigationKitURL()
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
            navigationKitURL: navigationKitURL,
            outputDirectory: outputDirectory,
            useLocalization: useLocalization,
            localizationLanguages: localizationLanguages
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

        print("")
        print("  Available languages (English is always included):")
        for (i, lang) in available.enumerated() {
            let index = String(format: "%2d", i + 1)
            print("    \(index). \(lang.label) (\(lang.code))")
        }
        print("")

        let input = askSub("Enter numbers separated by spaces, or press Enter to skip: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else { return (true, []) }

        let selected = trimmed
            .split(separator: " ")
            .compactMap { Int($0) }
            .filter { $0 >= 1 && $0 <= available.count }
            .map { available[$0 - 1].code }

        // deduplicate while preserving order
        var seen = Set<String>()
        let languages = selected.filter { seen.insert($0).inserted }

        return (true, languages)
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

    // MARK: - NavigationKit URL

    private mutating func askNavigationKitURL() -> String {
        let defaultValue = "https://github.com/KociucKy/NavigationKit"
        let input = ask("NavigationKit SPM URL [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
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

        print("  Tabs:")
        for tab in config.tabs {
            print("    - \(tab.sanitizedName) (\(tab.sfSymbol))")
        }

        print("  Build configs:   Mock, Dev, Prod")
        print("  Team ID:         \(config.teamID ?? "none")")
        print("  NavigationKit:   \(config.navigationKitURL)")
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

        guard shouldOfferOutput || shouldOfferTeamID else { return }

        var parts: [String] = []
        if shouldOfferOutput { parts.append("output directory") }
        if shouldOfferTeamID { parts.append("Team ID") }
        let label = parts.joined(separator: " and ")

        let save = askYesNo("Save \(label) as defaults for future projects?", default: true)
        guard save else { return }

        ConfigStore.update { c in
            if shouldOfferOutput {
                c.defaultOutputDirectory = config.outputDirectory
            }
            if shouldOfferTeamID {
                c.defaultTeamID = config.teamID
            }
        }

        print("  ✅ Defaults saved. Run 'boilerkit config' to view or change them.")
        print("")
    }

    // MARK: - Helpers

    /// Numbered prompt — increments the step counter once, then re-prompts
    /// without incrementing on validation retries.
    private mutating func ask(_ prompt: String) -> String {
        step += 1
        print("  \(step). \(prompt)", terminator: "")
        guard let line = readLine() else { exit(0) }
        return line
    }

    /// Re-prompt under the same step number after a validation error.
    private mutating func reask(_ prompt: String) -> String {
        print("  \(step). \(prompt)", terminator: "")
        guard let line = readLine() else { exit(0) }
        return line
    }

    /// Numbered yes/no prompt — increments the step counter.
    private mutating func askYesNo(_ prompt: String, default defaultValue: Bool) -> Bool {
        let hint = defaultValue ? "[Y/n]" : "[y/N]"
        let input = ask("\(prompt) \(hint): ")
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed.isEmpty { return defaultValue }
        return trimmed == "y" || trimmed == "yes"
    }

    /// Un-numbered sub-prompt for follow-up inputs within the same step
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
