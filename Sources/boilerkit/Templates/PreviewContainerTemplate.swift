// MARK: - PreviewContainerTemplate

enum PreviewContainerTemplate {
    static func render(config: ProjectConfig) -> String {
        let swiftDataImport = config.useSwiftData ? "\nimport SwiftData" : ""

        return """
        import SwiftUI\(swiftDataImport)

        // MARK: - PreviewContainer

        @MainActor
        final class PreviewContainer {

            // MARK: - Shared

            static let shared = PreviewContainer()

            // MARK: - Properties

            let dependencies: Dependencies
            let coreInteractor: CoreInteractor

            // MARK: - Init

            private init() {
                dependencies = Dependencies(configuration: .mock)
                coreInteractor = CoreInteractor(container: dependencies.container)
            }
        }
        """
    }
}
