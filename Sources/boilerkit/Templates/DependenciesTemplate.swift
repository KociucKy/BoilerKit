// MARK: - DependenciesTemplate

enum DependenciesTemplate {
    static func render(config: ProjectConfig) -> String {
        let swiftDataImport = config.useSwiftData ? "\nimport SwiftData" : ""
        let modelContainerProperty = config.useSwiftData
            ? "\n        let modelContainer: ModelContainer"
            : ""
        let modelContainerInit = config.useSwiftData
            ? "\n                modelContainer = try! ModelContainer(for: \(entityTypes(config: config)))"
            : ""

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

            let container: DependencyContainer\(modelContainerProperty)

            // MARK: - Init

            init(configuration: BuildConfiguration) {
                container = DependencyContainer()\(modelContainerInit)
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

    private static func entityTypes(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else { return "" }
        return "\(entityName)Entity.self"
    }
}
