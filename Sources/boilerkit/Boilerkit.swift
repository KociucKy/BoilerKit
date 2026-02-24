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
            abstract: "Interactively generate a new iOS Xcode project."
        )

        // MARK: - Run

        func run() throws {
            let config = Wizard().run()

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

        @Flag(name: .long, help: "Clear the default output directory.")
        var clearOutput: Bool = false

        @Flag(name: .long, help: "Clear the default Apple Team ID.")
        var clearTeamId: Bool = false

        // MARK: - Run

        func run() throws {
            let hasChanges = output != nil || teamId != nil || clearOutput || clearTeamId

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
            print("  ──────────────────────────────────────")
            print("")
        }
    }
}
