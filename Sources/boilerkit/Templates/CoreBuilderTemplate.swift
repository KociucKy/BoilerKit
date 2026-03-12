// MARK: - CoreBuilderTemplate

enum CoreBuilderTemplate {
    static func render(config: ProjectConfig) -> String {
        let isSingleTab = config.tabs.count == 1

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

        let devSettingsMethod = config.useDevSettings ? """


                func devSettingsView(router: Router) -> some View {
                    DevSettingsView(
                        presenter: DevSettingsPresenter(
                            interactor: interactor,
                            router: CoreRouter(router: router, builder: self)
                        )
                    )
                }
            """ : ""

        let buildBody: String
        let tabBarSection: String

        if isSingleTab, let tab = config.tabs.first {
            buildBody = """
                    RouterView { router in
                        \(tab.sanitizedName.lowercased())View(router: router)
                    }
                    .any()
            """
            tabBarSection = ""
        } else {
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

            buildBody = "tabBarView().any()"
            tabBarSection = """


                // MARK: - Tab Bar

                func tabBarView() -> some View {
                    TabBarView(
                        tabs: [
            \(tabScreens)
                        ]
                    )
                }
            """
        }

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
                \(buildBody)
            }\(tabBarSection)

            // MARK: - Tab Views

        \(tabBuilderMethods)\(devSettingsMethod)
        }
        """
    }
}
