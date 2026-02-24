// MARK: - AppTemplate

enum AppTemplate {
    static func render(config: ProjectConfig) -> String {
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
}
