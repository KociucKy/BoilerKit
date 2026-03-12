// MARK: - CoreRouterTemplate

enum CoreRouterTemplate {
    static func render(config: ProjectConfig) -> String {
        let devSettingsMethods = config.useDevSettings ? """

                func presentDevSettings() {
                    router.showScreen(.sheet, onDismiss: nil) { router in
                        builder.devSettingsView(router: router)
                    }
                }

                func dismissDevSettings() {
                    router.dismissScreen()
                }
            """ : ""

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

            func popToRoot() {
                router.popToRoot()
            }

            func dismissToRoot() {
                router.dismissToRoot()
            }

            func dismissModal() {
                router.dismissModal()
            }

            func dismissAlert() {
                router.dismissAlert()
            }\(devSettingsMethods)
        }
        """
    }
}
