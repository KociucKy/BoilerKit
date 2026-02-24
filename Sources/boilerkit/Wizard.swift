import Foundation

// MARK: - Wizard

struct Wizard {

    // MARK: - Run

    func run() -> ProjectConfig {
        printBanner()

        let appName = askAppName()
        let bundleID = askBundleID(appName: appName)
        let platforms = askPlatforms()
        let deploymentTargets = askDeploymentTargets(for: platforms)
        let swiftVersion = askSwiftVersion()
        let (useSwiftData, entityName) = askSwiftData()
        let tabs = askTabs()
        let teamID = askTeamID()
        let navigationKitURL = askNavigationKitURL()
        let outputDirectory = askOutputDirectory()

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
            outputDirectory: outputDirectory
        )

        printSummary(config)
        confirmGeneration()

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

    private func askAppName() -> String {
        while true {
            let input = ask("App name (e.g. MyApp, no spaces): ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else {
                printError("App name cannot be empty.")
                continue
            }

            guard !trimmed.contains(" ") else {
                printError("App name cannot contain spaces. Use PascalCase (e.g. MyApp).")
                continue
            }

            guard trimmed.first?.isLetter == true else {
                printError("App name must start with a letter.")
                continue
            }

            return trimmed
        }
    }

    // MARK: - Bundle ID

    private func askBundleID(appName: String) -> String {
        let defaultValue = "com.yourcompany.\(appName.lowercased())"
        let input = ask("Bundle ID [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - Platforms

    private func askPlatforms() -> [Platform] {
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

    private func askDeploymentTargets(for platforms: [Platform]) -> [Platform: String] {
        print("")
        print("  Deployment targets (press Enter to accept defaults):")

        var targets: [Platform: String] = [:]

        for platform in platforms {
            let defaultValue = platform.defaultDeploymentTarget
            let input = ask("  \(platform.rawValue) [\(defaultValue)]: ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)
            targets[platform] = trimmed.isEmpty ? defaultValue : trimmed
        }

        return targets
    }

    // MARK: - Swift Version

    private func askSwiftVersion() -> String {
        let defaultValue = "6.0"
        let input = ask("Swift version [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - SwiftData

    private func askSwiftData() -> (Bool, String?) {
        let useSwiftData = askYesNo("Use SwiftData for persistence?", default: true)

        guard useSwiftData else { return (false, nil) }

        let input = ask("First entity name (e.g. Item), or press Enter to skip: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let entityName = trimmed.isEmpty ? nil : trimmed.capitalized

        return (true, entityName)
    }

    // MARK: - Tabs

    private func askTabs() -> [Tab] {
        var count: Int = 0

        while true {
            let input = ask("Number of tabs (1–6): ")
            let trimmed = input.trimmingCharacters(in: .whitespaces)

            guard let value = Int(trimmed), value >= 1, value <= 6 else {
                printError("Please enter a number between 1 and 6.")
                continue
            }

            count = value
            break
        }

        print("")
        print("  Configure each tab (name + SF Symbol):")

        var tabs: [Tab] = []

        for i in 1...count {
            print("  Tab \(i):")
            let name = askTabName(index: i)
            let symbol = askSFSymbol(tabName: name)
            tabs.append(Tab(name: name, sfSymbol: symbol))
        }

        return tabs
    }

    private func askTabName(index: Int) -> String {
        while true {
            let input = ask("    Name (e.g. Home): ")
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

    private func askSFSymbol(tabName: String) -> String {
        let defaultValue = "circle"
        let input = ask("    SF Symbol [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - Team ID

    private func askTeamID() -> String? {
        let input = ask("Apple Team ID (press Enter to use manual signing): ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - NavigationKit URL

    private func askNavigationKitURL() -> String {
        let defaultValue = "https://github.com/KociucKy/NavigationKit"
        let input = ask("NavigationKit SPM URL [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    // MARK: - Output Directory

    private func askOutputDirectory() -> String {
        let defaultValue = FileManager.default.currentDirectoryPath
        let input = ask("Output directory [\(defaultValue)]: ")
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultValue : trimmed
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

        print("  Tabs:")
        for tab in config.tabs {
            print("    - \(tab.sanitizedName) (\(tab.sfSymbol))")
        }

        print("  Build configs:   Mock, Dev, Prod")
        print("  Team ID:         \(config.teamID ?? "manual signing")")
        print("  NavigationKit:   \(config.navigationKitURL)")
        print("  Output:          \(config.outputDirectory)")
        print("  ──────────────────────────────────────")
        print("")
    }

    // MARK: - Confirmation

    private func confirmGeneration() {
        while true {
            let input = ask("Generate project? [Y/n]: ")
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
            }
        }
    }

    // MARK: - Helpers

    private func ask(_ prompt: String) -> String {
        print("  \(prompt)", terminator: "")
        return readLine() ?? ""
    }

    private func askYesNo(_ prompt: String, default defaultValue: Bool) -> Bool {
        let hint = defaultValue ? "[Y/n]" : "[y/N]"
        let input = ask("\(prompt) \(hint): ")
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

        if trimmed.isEmpty { return defaultValue }
        return trimmed == "y" || trimmed == "yes"
    }

    private func printError(_ message: String) {
        print("  ⚠️  \(message)")
    }

    private func printWarning(_ message: String) {
        print("  ⚠️  \(message)")
    }
}
