// MARK: - CoreBuilderTemplate

enum CoreBuilderTemplate {
    static func render(config: ProjectConfig) -> String {
        let tabScreens = config.tabs.map { tab in
            """
                        TabBarScreen(
                            title: "\(tab.sanitizedName)",
                            systemImage: "\(tab.sfSymbol)",
                            screen: {
                                RouterView { router in
                                    \(tab.sanitizedName.lowercased())View(router: router)
                                }
                                .any()
                            }
                        )
            """
        }.joined(separator: ",\n")

        let tabBuilderMethods = config.tabs.map { tab in
            """
                func \(tab.sanitizedName.lowercased())View(router: Router) -> some View {
                    \(tab.sanitizedName)View(
                        presenter: \(tab.sanitizedName)Presenter(
                            interactor: interactor,
                            router: CoreRouter(router: router, builder: self)
                        )
                    )
                }
            """
        }.joined(separator: "\n\n")

        return """
        import SwiftUI
        import NavigationKit

        typealias RouterView = NavigationKit.RouterView

        // MARK: - CoreBuilder

        @MainActor
        struct CoreBuilder: Builder {

            // MARK: - Properties

            let interactor: CoreInteractor

            // MARK: - Builder

            func build() -> AnyView {
                tabBarView().any()
            }

            // MARK: - Tab Bar

            func tabBarView() -> some View {
                TabBarView(
                    tabs: [
        \(tabScreens)
                    ]
                )
            }

            // MARK: - Tab Views

        \(tabBuilderMethods)
        }
        """
    }
}
