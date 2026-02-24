// MARK: - TabBarTemplate

enum TabBarTemplate {
    static func render(config: ProjectConfig) -> String {
        return """
        import SwiftUI

        // MARK: - TabBarScreen

        struct TabBarScreen: Identifiable {

            // MARK: - Properties

            var id: String { title }
            let title: String
            let systemImage: String
            let role: TabRole?
            @ViewBuilder var screen: () -> AnyView

            // MARK: - Init

            init(
                title: String,
                systemImage: String,
                role: TabRole? = nil,
                screen: @escaping () -> AnyView
            ) {
                self.title = title
                self.systemImage = systemImage
                self.role = role
                self.screen = screen
            }
        }

        // MARK: - TabBarView

        struct TabBarView: View {

            // MARK: - Properties

            var tabs: [TabBarScreen]

            // MARK: - Body

            var body: some View {
                TabView {
                    ForEach(tabs) { tab in
                        if let role = tab.role {
                            Tab(role: role) {
                                tabView(tab)
                            }
                        } else {
                            Tab {
                                tab.screen()
                            } label: {
                                Label(tab.title, systemImage: tab.systemImage)
                            }
                        }
                    }
                }
            }

            private func tabView(_ tab: TabBarScreen) -> some View {
                tab.screen()
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
            }
        }
        """
    }
}
