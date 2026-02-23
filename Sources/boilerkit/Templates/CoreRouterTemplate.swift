// MARK: - CoreRouterTemplate

enum CoreRouterTemplate {
    static func render(config: ProjectConfig) -> String {
        let conformances = config.tabs
            .map { "\($0.sanitizedName)Router" }
            .joined(separator: ",\n    ")

        let conformanceList = config.tabs.isEmpty
            ? ""
            : ": \(conformances)"

        return """
        import NavigationKit

        // MARK: - CoreRouter

        @MainActor
        final class CoreRouter\(conformanceList) {

            // MARK: - Properties

            private let router: NavigationKit.Router

            // MARK: - Init

            init(router: NavigationKit.Router) {
                self.router = router
            }

            // MARK: - Navigation

            func dismissScreen() {
                router.dismissScreen()
            }

            func dismissModal() {
                router.dismissModal()
            }
        }
        """
    }
}
