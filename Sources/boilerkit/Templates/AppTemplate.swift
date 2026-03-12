// MARK: - AppTemplate

enum AppTemplate {
    static func render(config: ProjectConfig) -> String {
        if config.useOnboarding {
            return renderWithOnboarding(config: config)
        } else {
            return renderDefault(config: config)
        }
    }

    private static func renderDefault(config: ProjectConfig) -> String {
        """
        import SwiftUI

        @main
        struct \(config.appName)App: App {

            // MARK: - Properties

            @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

            // MARK: - Body

            var body: some Scene {
                WindowGroup {
                    delegate.builder.build()
                }
            }
        }
        """
    }

    private static func renderWithOnboarding(config: ProjectConfig) -> String {
        """
        import SwiftUI

        @main
        struct \(config.appName)App: App {

            // MARK: - Properties

            @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

            // MARK: - Body

            var body: some Scene {
                WindowGroup {
                    AppViewBuilder(
                        showOnboarding: delegate.appState.showOnboarding,
                        mainView: { delegate.builder.build() },
                        onboardingView: { delegate.onboardingBuilder.build() }
                    )
                }
            }
        }
        """
    }
}
