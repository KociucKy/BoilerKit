// MARK: - DependenciesTemplate

enum DependenciesTemplate {
    static func render(config: ProjectConfig) -> String {
        let swiftDataImport = config.useSwiftData ? "\nimport SwiftData" : ""
        let modelContainerInit = config.useSwiftData ? modelContainerBlock(config: config) : ""
        let managerRegistrations = config.useSwiftData ? swiftDataRegistrations(config: config) : noSwiftDataRegistrations()
        let devPreviewManagerProps = config.useSwiftData ? devPreviewManagerProperties(config: config) : ""
        let devPreviewManagerInit = config.useSwiftData ? devPreviewManagerInit(config: config) : ""
        let devPreviewContainerRegistrations = config.useSwiftData ? devPreviewContainerBody(config: config) : ""

        return """
        import Foundation\(swiftDataImport)

        // MARK: - BuildConfiguration

        enum BuildConfiguration {
            case mock, dev, prod
        }

        // MARK: - Dependencies

        @MainActor
        struct Dependencies {

            // MARK: - Properties

            let dependencyContainer: DependencyContainer

            // MARK: - Init

            init(config: BuildConfiguration) {
        \(modelContainerInit)
                let dependencyContainer = DependencyContainer()
        \(managerRegistrations)
                self.dependencyContainer = dependencyContainer
            }
        }

        // MARK: - DevPreview

        @MainActor
        final class DevPreview {

            // MARK: - Shared

            static let shared = DevPreview()

            // MARK: - Properties
        \(devPreviewManagerProps)
            var container: DependencyContainer {
                let container = DependencyContainer()
        \(devPreviewContainerRegistrations)
                return container
            }

            // MARK: - Init

            init() {
        \(devPreviewManagerInit)
            }
        }
        """
    }

    // MARK: - SwiftData blocks

    private static func modelContainerBlock(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else { return "" }
        return """
                let modelContainer = try! ModelContainer(for: \(entityName)Entity.self)
        """
    }

    private static func swiftDataRegistrations(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else { return noSwiftDataRegistrations() }
        let lower = entityName.lowercased()
        return """
                let \(lower)Manager: \(entityName)Manager

                switch config {
                case .mock:
                    \(lower)Manager = \(entityName)Manager(
                        repository: Mock\(entityName)Repository()
                    )
                case .dev, .prod:
                    \(lower)Manager = \(entityName)Manager(
                        repository: SwiftData\(entityName)Repository(container: modelContainer)
                    )
                }

                dependencyContainer.register(\(entityName)Manager.self, service: \(lower)Manager)
        """
    }

    private static func noSwiftDataRegistrations() -> String {
        """
                // TODO: Register managers
        """
    }

    // MARK: - DevPreview blocks

    private static func devPreviewManagerProperties(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else { return "" }
        let lower = entityName.lowercased()
        return """

            let \(lower)Manager: \(entityName)Manager

        """
    }

    private static func devPreviewManagerInit(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else {
            return "        // TODO: Initialize preview managers"
        }
        let lower = entityName.lowercased()
        return """
                self.\(lower)Manager = \(entityName)Manager(
                    repository: Mock\(entityName)Repository()
                )
        """
    }

    private static func devPreviewContainerBody(config: ProjectConfig) -> String {
        guard let entityName = config.swiftDataEntityName else { return "" }
        let lower = entityName.lowercased()
        return """
                container.register(\(entityName)Manager.self, service: \(lower)Manager)
        """
    }
}
