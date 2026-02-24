// MARK: - AppDelegateTemplate

enum AppDelegateTemplate {
    static func render(config: ProjectConfig) -> String {
        """
        import UIKit

        final class AppDelegate: NSObject, UIApplicationDelegate {

            // MARK: - Properties

            var dependencies: Dependencies!
            var builder: CoreBuilder!

            // MARK: - UIApplicationDelegate

            func application(
                _ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
            ) -> Bool {
                #if MOCK
                let config = BuildConfiguration.mock
                print("✅ MOCK")
                #elseif DEV
                let config = BuildConfiguration.dev
                print("✅ DEV")
                #else
                let config = BuildConfiguration.prod
                print("✅ PROD")
                #endif

                dependencies = Dependencies(config: config)
                builder = CoreBuilder(
                    interactor: CoreInteractor(container: dependencies.dependencyContainer)
                )

                return true
            }
        }
        """
    }
}
