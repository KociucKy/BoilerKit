import Foundation

// MARK: - SwiftPackage

struct SwiftPackage: Codable, Equatable {
    var name: String
    var url: String
}

// MARK: - BoilerkitConfig

struct BoilerkitConfig: Codable {

    // MARK: - Properties

    var defaultOutputDirectory: String?
    var defaultTeamID: String?
    var defaultPackages: [SwiftPackage] = []
}

// MARK: - ConfigStore

enum ConfigStore {

    // MARK: - Path

    private static var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".boilerkit")
    }

    private static var configFileURL: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    // MARK: - Load

    static func load() -> BoilerkitConfig {
        guard
            FileManager.default.fileExists(atPath: configFileURL.path),
            let data = try? Data(contentsOf: configFileURL),
            let config = try? JSONDecoder().decode(BoilerkitConfig.self, from: data)
        else {
            return BoilerkitConfig()
        }
        return config
    }

    // MARK: - Save

    static func save(_ config: BoilerkitConfig) {
        do {
            try FileManager.default.createDirectory(
                at: configDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL, options: .atomic)
        } catch {
            print("  ⚠️  Could not save config: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    static func update(_ block: (inout BoilerkitConfig) -> Void) {
        var config = load()
        block(&config)
        save(config)
    }
}
