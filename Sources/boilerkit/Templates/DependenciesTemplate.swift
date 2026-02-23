// MARK: - DependenciesTemplate

enum DependenciesTemplate {
    static func render(config: ProjectConfig) -> String {
        let swiftDataImport = config.useSwiftData ? "\nimport SwiftData" : ""
        let swiftDataContainer = config.useSwiftData ? swiftDataContainerBlock(config: config) : ""

        return """
        import Foundation\(swiftDataImport)

        // MARK: - BuildConfiguration

        enum BuildConfiguration {
            case mock
            case dev
            case prod
        }

        // MARK: - Dependencies

        @MainActor
        final class Dependencies {

            // MARK: - Properties

            let container: DependencyContainer
            \(swiftDataContainer)
            // MARK: - Init

            init(configuration: BuildConfiguration) {
                container = DependencyContainer()
                registerDependencies(configuration: configuration)
            }

            // MARK: - Registration

            private func registerDependencies(configuration: BuildConfiguration) {
                switch configuration {
                case .mock:
                    registerMockDependencies()
                case .dev, .prod:
                    registerLiveDependencies()
                }
            }

            private func registerMockDependencies() {
                // TODO: Register mock managers
            }

            private func registerLiveDependencies() {
                // TODO: Register live managers
            }
        }
        """
        .replacingOccurrences(of: "{{APP_NAME}}", with: config.appName)
    }

    private static func swiftDataContainerBlock(config: ProjectConfig) -> String {
        "let modelContainer: ModelContainer\n"
    }
}
