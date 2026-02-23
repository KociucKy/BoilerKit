import ArgumentParser
import Foundation

// MARK: - Boilerkit

@main
struct Boilerkit: ParsableCommand {

    // MARK: - Configuration

    static let configuration = CommandConfiguration(
        commandName: "boilerkit",
        abstract: "iOS app project generator — scaffolds a full Xcode project following VIPER/RIBs architecture."
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
