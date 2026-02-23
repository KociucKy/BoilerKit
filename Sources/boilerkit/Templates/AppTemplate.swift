// MARK: - AppTemplate

enum AppTemplate {
    static func render(config: ProjectConfig) -> String {
        """
        import SwiftUI

        @main
        struct {{APP_NAME}}App: App {

            // MARK: - Properties

            @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

            // MARK: - Body

            var body: some Scene {
                WindowGroup {
                    if let dependencies = appDelegate.dependencies {
                        CoreBuilder(dependencies: dependencies).rootView()
                    }
                }
            }
        }
        """
        .replacingOccurrences(of: "{{APP_NAME}}", with: config.appName)
    }
}
