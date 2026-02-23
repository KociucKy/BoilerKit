// MARK: - CoreInteractorTemplate

enum CoreInteractorTemplate {
    static func render(config: ProjectConfig) -> String {
        let conformances = config.tabs
            .map { "\($0.sanitizedName)Interactor" }
            .joined(separator: ",\n    ")

        let conformanceList = config.tabs.isEmpty
            ? ""
            : ": \(conformances)"

        return """
        import Foundation

        // MARK: - CoreInteractor

        @MainActor
        final class CoreInteractor\(conformanceList) {

            // MARK: - Properties

            private let container: DependencyContainer

            // MARK: - Init

            init(container: DependencyContainer) {
                self.container = container
            }
        }
        """
    }
}
