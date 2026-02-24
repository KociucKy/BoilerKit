// MARK: - CoreInteractorTemplate

enum CoreInteractorTemplate {
    static func render(config: ProjectConfig) -> String {
        return """
        import Foundation

        // MARK: - CoreInteractor

        @MainActor
        struct CoreInteractor {

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
