// MARK: - TabBarTemplate

enum TabBarTemplate {
    static func render(config: ProjectConfig) -> String {
        let tabItems = config.tabs.map { tab in
            """
                    \(tab.sanitizedName)Tab(builder: builder, router: router)
                        .tabItem {
                            Label("\(tab.sanitizedName)", systemImage: "\(tab.sfSymbol)")
                        }
            """
        }.joined(separator: "\n")

        let tabViews = config.tabs.map { tab in
            """

            // MARK: - \(tab.sanitizedName)Tab

            private struct \(tab.sanitizedName)Tab: View {

                // MARK: - Properties

                let builder: CoreBuilder
                let router: NavigationKit.Router

                // MARK: - Body

                var body: some View {
                    builder.\(tab.sanitizedName.lowercased())View(router: router)
                }
            }
            """
        }.joined(separator: "\n")

        return """
        import SwiftUI
        import NavigationKit

        // MARK: - TabBarView

        struct TabBarView: View {

            // MARK: - Properties

            let builder: CoreBuilder
            let router: NavigationKit.Router

            // MARK: - Body

            var body: some View {
                TabView {
        \(tabItems)
                }
            }
        }
        \(tabViews)
        """
    }
}
