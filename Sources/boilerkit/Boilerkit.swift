import ArgumentParser
import Foundation

// MARK: - Boilerkit (root command)

@main
struct Boilerkit: ParsableCommand {

    // MARK: - Configuration

    static let configuration = CommandConfiguration(
        commandName: "boilerkit",
        abstract: "iOS app project generator — scaffolds a full Xcode project following VIPER/RIBs architecture.",
        subcommands: [Generate.self, Config.self],
        defaultSubcommand: Generate.self
    )
}

// MARK: - Generate

extension Boilerkit {

    struct Generate: ParsableCommand {

        // MARK: - Configuration

        static let configuration = CommandConfiguration(
            commandName: "generate",
            abstract: "Interactively generate a new iOS Xcode project.",
            discussion: """
            Launches the interactive wizard. Answer each question and boilerkit writes
            all source files, then runs xcodegen to produce a ready-to-open .xcodeproj.

            Wizard questions (in order):
              1.  App name            — PascalCase identifier, no spaces (e.g. MyApp)
              2.  Bundle ID           — reverse-DNS, defaults to com.yourcompany.<appname>
              3.  Apple Team ID       — skipped if a default is stored
              4.  Target platforms    — iOS always included; optionally add macOS/watchOS/tvOS/visionOS
              5.  Deployment targets  — per-platform minimum OS version
              6.  Swift version       — defaults to 6.0
              7.  SwiftData           — optional persistence stack + first entity name
              8.  Localizations       — optional String Catalog + language selection
              9.  Code quality tools  — SwiftLint (on by default) and SwiftFormat (off by default)
              10. Tabs                — 1–6 tabs, each with a name and SF Symbol
              11. DevSettings         — optional DEBUG-only settings panel wired to the first tab
              12. Onboarding          — optional WelcomeView → OnboardingCompletedView flow
              13. Packages            — NavigationKit always included; add or remove extras
              14. Output directory    — skipped if a default is stored

            After answering all questions, a summary is printed and you confirm before
            any files are written.

            Use 'boilerkit config' to pre-set output directory and Team ID so those
            questions are skipped automatically.
            """
        )

        // MARK: - Run

        func run() throws {
            var wizard = Wizard()
            let config = wizard.run()

            print("  🔨 Generating source files...")

            do {
                try FileGenerator(config: config).generate()
            } catch {
                printError("Failed to generate source files: \(error)")
                throw ExitCode.failure
            }

            print("  🔨 Running XcodeGen...")

            do {
                try XcodeGenRunner(config: config).run()
            } catch XcodeGenError.notInstalled {
                printError("xcodegen is not installed. Run: brew install xcodegen")
                printError("Your source files have been written to \(config.outputDirectory)/\(config.appName).")
                printError("Once xcodegen is installed, run: xcodegen generate --spec \(config.outputDirectory)/\(config.appName)/project.yml")
                throw ExitCode.failure
            } catch {
                printError("XcodeGen failed: \(error)")
                throw ExitCode.failure
            }

            printSuccess(config: config)
        }

        // MARK: - Helpers

        private func printSuccess(config: ProjectConfig) {
            print("")
            print("  ──────────────────────────────────────")
            print("  ✅ \(config.appName) is ready!")
            print("  ──────────────────────────────────────")
            print("  Open your project:")
            print("  open \(config.outputDirectory)/\(config.appName)/\(config.appName).xcodeproj")
            print("")
        }

        private func printError(_ message: String) {
            print("  ❌ \(message)")
        }
    }
}

// MARK: - Config

extension Boilerkit {

    struct Config: ParsableCommand {

        // MARK: - Configuration

        static let configuration = CommandConfiguration(
            commandName: "config",
            abstract: "Get or set default values used by the generate wizard."
        )

        // MARK: - Options

        @Option(name: .long, help: "Set the default output directory.")
        var output: String?

        @Option(name: .long, help: "Set the default Apple Team ID.")
        var teamId: String?

        @Option(name: .long, help: "Add a default package (format: \"Name=https://url=branch\").")
        var addPackage: [String] = []

        @Option(name: .long, help: "Remove a default package by name.")
        var removePackage: [String] = []

        @Flag(name: .long, help: "Clear the default output directory.")
        var clearOutput: Bool = false

        @Flag(name: .long, help: "Clear the default Apple Team ID.")
        var clearTeamId: Bool = false

        // MARK: - Run

        func run() throws {
            let hasChanges = output != nil || teamId != nil || clearOutput || clearTeamId
                || !addPackage.isEmpty || !removePackage.isEmpty

            if hasChanges {
                ConfigStore.update { config in
                    if let output {
                        let expanded = (output as NSString).expandingTildeInPath
                        config.defaultOutputDirectory = expanded
                        print("  ✅ Default output directory set to: \(expanded)")
                    }
                    if clearOutput {
                        config.defaultOutputDirectory = nil
                        print("  ✅ Default output directory cleared.")
                    }
                    if let teamId {
                        config.defaultTeamID = teamId
                        print("  ✅ Default Team ID set to: \(teamId)")
                    }
                    if clearTeamId {
                        config.defaultTeamID = nil
                        print("  ✅ Default Team ID cleared.")
                    }
                    for raw in addPackage {
                        let parts = raw.split(separator: "=", maxSplits: 2).map(String.init)
                        guard parts.count == 3, !parts[0].isEmpty, !parts[1].isEmpty, !parts[2].isEmpty else {
                            print("  ⚠️  Skipping '\(raw)' — format must be Name=https://url=branch")
                            continue
                        }
                        let (name, url, branch) = (parts[0], parts[1], parts[2])
                        if let existing = config.defaultPackages.firstIndex(where: {
                            $0.name.lowercased() == name.lowercased()
                        }) {
                            config.defaultPackages[existing].url = url
                            config.defaultPackages[existing].branch = branch
                            print("  ✅ Updated package '\(name)': \(url) (\(branch))")
                        } else {
                            config.defaultPackages.append(SwiftPackage(name: name, url: url, branch: branch))
                            print("  ✅ Added default package '\(name)': \(url) (\(branch))")
                        }
                    }
                    for name in removePackage {
                        let before = config.defaultPackages.count
                        config.defaultPackages.removeAll {
                            $0.name.lowercased() == name.lowercased()
                        }
                        if config.defaultPackages.count < before {
                            print("  ✅ Removed default package '\(name)'.")
                        } else {
                            print("  ⚠️  No default package named '\(name)' found.")
                        }
                    }
                }
            }

            printCurrentConfig()
        }

        // MARK: - Helpers

        private func printCurrentConfig() {
            let config = ConfigStore.load()
            print("")
            print("  ──────────────────────────────────────")
            print("  boilerkit config")
            print("  ──────────────────────────────────────")
            print("  Default output dir:  \(config.defaultOutputDirectory ?? "(not set)")")
            print("  Default Team ID:     \(config.defaultTeamID ?? "(not set)")")
            if config.defaultPackages.isEmpty {
                print("  Default packages:    (none saved)")
            } else {
                print("  Default packages:")
                for pkg in config.defaultPackages {
                    print("    - \(pkg.name)  \(pkg.url)  (\(pkg.branch))")
                }
            }
            print("  ──────────────────────────────────────")
            print("")
        }
    }
}
