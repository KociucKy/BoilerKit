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
        \(packageDependenciesYML())
            info:
              path: \(config.appName)/Info.plist
              properties:
                CFBundleDisplayName: \(config.appName)
                CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"
                CFBundleShortVersionString: "$(MARKETING_VERSION)"
                UILaunchScreen: {}
                UISupportedInterfaceOrientations:
                  - UIInterfaceOrientationPortrait
                  - UIInterfaceOrientationPortraitUpsideDown
                  - UIInterfaceOrientationLandscapeLeft
                  - UIInterfaceOrientationLandscapeRight
                UISupportedInterfaceOrientations~ipad:
                  - UIInterfaceOrientationPortrait
                  - UIInterfaceOrientationPortraitUpsideDown
                  - UIInterfaceOrientationLandscapeLeft
                  - UIInterfaceOrientationLandscapeRight
            settings:
              base:
                SWIFT_VERSION: \(config.swiftVersion)
                MARKETING_VERSION: "1.0"
                CURRENT_PROJECT_VERSION: "1"
                ENABLE_USER_SCRIPT_SANDBOXING: YES
                ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
                ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        \(localizationSettingsYML())\
        \(signingSettingsYML())
              configs:
                Mock:
                  PRODUCT_BUNDLE_IDENTIFIER: \(config.bundleID).mock
                  INFOPLIST_KEY_CFBundleDisplayName: "\(config.appName) - Mock"
                Debug:
                  PRODUCT_BUNDLE_IDENTIFIER: \(config.bundleID).dev
                  INFOPLIST_KEY_CFBundleDisplayName: "\(config.appName) - Dev"
                Release:
                  PRODUCT_BUNDLE_IDENTIFIER: \(config.bundleID)
                  INFOPLIST_KEY_CFBundleDisplayName: "\(config.appName)"
        \(preBuildScriptsYML())
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

        \(schemesYML())
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
        let entries = config.packages.map { pkg in
            "  \(pkg.name):\n    url: \(pkg.url)\n    branch: \"main\""
        }.joined(separator: "\n")
        return "packages:\n\(entries)"
    }

    private func packageDependenciesYML() -> String {
        config.packages.map { pkg in
            "          - package: \(pkg.name)"
        }.joined(separator: "\n")
    }

    private func preBuildScriptsYML() -> String {
        var entries: [String] = []

        if config.useLinting {
            entries.append(
                "      - name: SwiftLint\n" +
                "        script: |\n" +
                "          if which swiftlint > /dev/null; then\n" +
                "            swiftlint\n" +
                "          else\n" +
                "            echo \"warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint\"\n" +
                "          fi\n" +
                "        basedOnDependencyAnalysis: false"
            )
        }

        if config.useFormatting {
            entries.append(
                "      - name: SwiftFormat\n" +
                "        script: |\n" +
                "          if which swiftformat > /dev/null; then\n" +
                "            swiftformat .\n" +
                "          else\n" +
                "            echo \"warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat\"\n" +
                "          fi\n" +
                "        basedOnDependencyAnalysis: false"
            )
        }

        guard !entries.isEmpty else { return "" }
        return "    preBuildScripts:\n" + entries.joined(separator: "\n")
    }

    private func localizationSettingsYML() -> String {
        guard config.useLocalization else { return "" }
        return """
                LOCALIZATION_PREFERS_STRING_CATALOGS: YES

        """
    }

    private func signingSettingsYML() -> String {        if let teamID = config.teamID {
            return """
                    DEVELOPMENT_TEAM: \(teamID)
                    CODE_SIGN_STYLE: Automatic
            """
        } else {
            return """
                    CODE_SIGN_STYLE: Automatic
            """
        }
    }

    private func schemesYML() -> String {
        """
        schemes:
          \(config.appName) - Mock:
            build:
              targets:
                \(config.appName): all
            test:
              config: Mock
              targets:
                - \(config.appName)Tests
            run:
              config: Mock
            profile:
              config: Mock
            analyze:
              config: Mock
            archive:
              config: Mock

          \(config.appName) - Dev:
            build:
              targets:
                \(config.appName): all
            test:
              config: Debug
            run:
              config: Debug
            profile:
              config: Debug
            analyze:
              config: Debug
            archive:
              config: Debug

          \(config.appName) - Prod:
            build:
              targets:
                \(config.appName): all
            test:
              config: Release
            run:
              config: Release
              debugEnabled: false
            profile:
              config: Release
            analyze:
              config: Release
            archive:
              config: Release
        """
    }

    private func configurationsYML() -> String {
        """
        configs:
          Mock: debug
          Debug: debug
          Release: release

        settings:
          configs:
            Mock:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: MOCK
                ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS: YES
                SWIFT_EMIT_LOC_STRINGS: YES
            Debug:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEV
                ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS: YES
                SWIFT_EMIT_LOC_STRINGS: YES
            Release:
              base:
                SWIFT_ACTIVE_COMPILATION_CONDITIONS: ""
                ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS: YES
                SWIFT_EMIT_LOC_STRINGS: NO
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
