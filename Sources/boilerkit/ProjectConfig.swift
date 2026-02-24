// MARK: - Tab

struct Tab {
    let name: String
    let sfSymbol: String

    var sanitizedName: String {
        name.capitalized
    }
}

// MARK: - Platform

enum Platform: String, CaseIterable {
    case iOS
    case macOS
    case watchOS
    case tvOS
    case visionOS

    var defaultDeploymentTarget: String {
        switch self {
        case .iOS:       return "18.0"
        case .macOS:     return "15.0"
        case .watchOS:   return "11.0"
        case .tvOS:      return "18.0"
        case .visionOS:  return "2.0"
        }
    }

    var xcodePlatformKey: String {
        switch self {
        case .iOS:       return "iOS"
        case .macOS:     return "macOS"
        case .watchOS:   return "watchOS"
        case .tvOS:      return "tvOS"
        case .visionOS:  return "visionOS"
        }
    }
}

// MARK: - ProjectConfig

struct ProjectConfig {

    // MARK: - Properties

    let appName: String
    let bundleID: String
    let platforms: [Platform]
    let deploymentTargets: [Platform: String]
    let swiftVersion: String
    let useSwiftData: Bool
    let swiftDataEntityName: String?
    let tabs: [Tab]
    let teamID: String?
    let navigationKitURL: String
    let outputDirectory: String
    let useLocalization: Bool
    let localizationLanguages: [String]

    // MARK: - Computed

    var appNameLowercased: String {
        appName.lowercased()
    }

    var primaryPlatform: Platform {
        platforms.first ?? .iOS
    }

    var deploymentTarget: String {
        deploymentTargets[primaryPlatform] ?? primaryPlatform.defaultDeploymentTarget
    }
}
