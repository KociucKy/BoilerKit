import Foundation

// MARK: - XcodeGenRunner

struct XcodeGenRunner {

    // MARK: - Properties

    private let config: ProjectConfig

    // MARK: - Init

    init(config: ProjectConfig) {
        self.config = config
    }

    // MARK: - Run

    func run() throws {
        try checkXcodeGenInstalled()
        let projectYMLPath = try writeProjectYML()
        try runXcodeGen(projectYMLPath: projectYMLPath)
    }

    // MARK: - XcodeGen Check

    private func checkXcodeGenInstalled() throws {
        let result = shell("which xcodegen")
        guard result.exitCode == 0 else {
            throw XcodeGenError.notInstalled
        }
    }

    // MARK: - project.yml

    private func writeProjectYML() throws -> String {
        let root = config.outputDirectory.appending("/\(config.appName)")
        let path = "\(root)/project.yml"
        let content = buildProjectYML()

        guard let data = content.data(using: .utf8) else {
            throw XcodeGenError.encodingFailed
        }

        FileManager.default.createFile(atPath: path, contents: data)
        return path
    }

    private func buildProjectYML() -> String {
        let yml = """
        name: \(config.appName)
        options:
          bundleIdPrefix: \(bundleIDPrefix())
          deploymentTarget:
        \(deploymentTargetsYML())
          xcodeVersion: "16.0"
          swiftVersion: "\(config.swiftVersion)"
        \(packagesYML())
        targets:
          \(config.appName):
            type: application
            platform: \(platformsYML())
            deploymentTarget:
        \(deploymentTargetsYML(indent: 6))
            sources:
              - path: \(config.appName)
            resources:
              - path: \(config.appName)/Assets.xcassets
            dependencies:
              - package: NavigationKit
            settings:
              base:
                PRODUCT_BUNDLE_IDENTIFIER: \(config.bundleID)
                SWIFT_VERSION: \(config.swiftVersion)
        \(signingSettingsYML())
            scheme:
              testTargets:
                - \(config.appName)Tests

          \(config.appName)Tests:
            type: bundle.unit-test
            platform: \(platformsYML())
            deploymentTarget:
        \(deploymentTargetsYML(indent: 6))
            sources:
              - path: \(config.appName)Tests
            dependencies:
              - target: \(config.appName)
            settings:
              base:
                PRODUCT_BUNDLE_IDENTIFIER: \(config.bundleID).tests
                SWIFT_VERSION: \(config.swiftVersion)

        \(configurationsYML())
        """

        return yml
    }

    // MARK: - YML Sections

    private func bundleIDPrefix() -> String {
        let parts = config.bundleID.split(separator: ".")
        guard parts.count >= 2 else { return config.bundleID }
        return parts.dropLast().joined(separator: ".")
    }

    private func platformsYML() -> String {
        // XcodeGen uses the primary platform as a string for single-platform,
        // or a list for multi-platform targets
        if config.platforms.count == 1 {
            return config.platforms[0].xcodePlatformKey
        } else {
            return "[" + config.platforms.map(\.xcodePlatformKey).joined(separator: ", ") + "]"
        }
    }

    private func deploymentTargetsYML(indent: Int = 4) -> String {
        let spaces = String(repeating: " ", count: indent)
        return config.platforms.map { platform in
            let target = config.deploymentTargets[platform] ?? platform.defaultDeploymentTarget
            return "\(spaces)\(platform.xcodePlatformKey): \"\(target)\""
        }.joined(separator: "\n")
    }

    private func packagesYML() -> String {
        """
        packages:
          NavigationKit:
            url: \(config.navigationKitURL)
            from: "1.0.0"
        """
    }

    private func signingSettingsYML() -> String {
        if let teamID = config.teamID {
            return """
                    DEVELOPMENT_TEAM: \(teamID)
                    CODE_SIGN_STYLE: Automatic
            """
        } else {
            return """
                    CODE_SIGN_STYLE: Manual
            """
        }
    }

    private func configurationsYML() -> String {
        """
        configs:
          Mock: debug
          Dev: debug
          Prod: release

        configFiles:
          Mock:
            \(config.appName): ""
          Dev:
            \(config.appName): ""
          Prod:
            \(config.appName): ""

        settings:
          configs:
            Mock:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: MOCK
            Dev:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEV
            Prod:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: ""
        """
    }

    // MARK: - Run XcodeGen

    private func runXcodeGen(projectYMLPath: String) throws {
        let root = config.outputDirectory.appending("/\(config.appName)")
        let result = shell("xcodegen generate --spec \"\(projectYMLPath)\" --project \"\(root)\"")

        guard result.exitCode == 0 else {
            throw XcodeGenError.generationFailed(result.output)
        }
    }

    // MARK: - Shell Helper

    @discardableResult
    private func shell(_ command: String) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ShellResult(exitCode: 1, output: error.localizedDescription)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return ShellResult(exitCode: process.terminationStatus, output: output)
    }
}

// MARK: - ShellResult

private struct ShellResult {
    let exitCode: Int32
    let output: String
}

// MARK: - XcodeGenError

enum XcodeGenError: Error, CustomStringConvertible {
    case notInstalled
    case encodingFailed
    case generationFailed(String)

    var description: String {
        switch self {
        case .notInstalled:
            return """
            xcodegen is not installed.
            Install it with: brew install xcodegen
            """
        case .encodingFailed:
            return "Failed to encode project.yml content."
        case .generationFailed(let output):
            return "xcodegen failed:\n\(output)"
        }
    }
}
