// MARK: - CoreRouterTemplate

enum CoreRouterTemplate {
    static func render(config: ProjectConfig) -> String {
        return """
        import SwiftUI
        import NavigationKit

        // MARK: - CoreRouter

        @MainActor
        struct CoreRouter {

            // MARK: - Properties

            let router: Router
            let builder: CoreBuilder

            // MARK: - Navigation

            func dismissScreen() {
                router.dismissScreen()
            }

            func dismissModal() {
                router.dismissModal()
            }

            func dismissAlert() {
                router.dismissAlert()
            }
        }
        """
    }
}
