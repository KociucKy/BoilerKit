// MARK: - CoreBuilderTemplate

enum CoreBuilderTemplate {
    static func render(config: ProjectConfig) -> String {
        let tabBuilderMethods = config.tabs.map { tab in
            """
                func \(tab.sanitizedName.lowercased())View(router: NavigationKit.Router) -> some View {
                    let interactor = CoreInteractor(container: dependencies.container)
                    let coreRouter = CoreRouter(router: router)
                    let presenter = \(tab.sanitizedName)Presenter(interactor: interactor, router: coreRouter)
                    return \(tab.sanitizedName)View(presenter: presenter)
                }
            """
        }.joined(separator: "\n\n")

        return """
        import SwiftUI
        import NavigationKit

        // MARK: - CoreBuilder

        @MainActor
        struct CoreBuilder {

            // MARK: - Properties

            let dependencies: Dependencies

            // MARK: - Root

            func rootView() -> some View {
                RouterView { router in
                    TabBarView(builder: self, router: router)
                }
            }

            // MARK: - Tab Views

        \(tabBuilderMethods)
        }
        """
    }
}
