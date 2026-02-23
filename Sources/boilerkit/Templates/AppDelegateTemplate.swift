// MARK: - AppDelegateTemplate

enum AppDelegateTemplate {
    static func render(config: ProjectConfig) -> String {
        """
        import UIKit

        @MainActor
        final class AppDelegate: NSObject, UIApplicationDelegate {

            // MARK: - Properties

            private(set) var dependencies: Dependencies?

            // MARK: - UIApplicationDelegate

            func application(
                _ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
            ) -> Bool {
                #if MOCK
                let config = BuildConfiguration.mock
                #elseif DEV
                let config = BuildConfiguration.dev
                #else
                let config = BuildConfiguration.prod
                #endif

                dependencies = Dependencies(configuration: config)
                return true
            }
        }
        """
    }
}
