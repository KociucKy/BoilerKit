// MARK: - AppDelegateTemplate

enum AppDelegateTemplate {
    static func render(config: ProjectConfig) -> String {
        if config.useOnboarding {
            return renderWithOnboarding(config: config)
        } else {
            return renderDefault(config: config)
        }
    }

    private static func renderDefault(config: ProjectConfig) -> String {
        """
        import UIKit

        @MainActor
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

    private static func renderWithOnboarding(config: ProjectConfig) -> String {
        """
        import UIKit

        @MainActor
        final class AppDelegate: NSObject, UIApplicationDelegate {

            // MARK: - Properties

            var dependencies: Dependencies!
            var builder: CoreBuilder!
            var onboardingBuilder: OnboardingBuilder!
            var appState: OnboardingState!

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
                appState = OnboardingState()
                dependencies.dependencyContainer.register(OnboardingState.self, service: appState)
                builder = CoreBuilder(
                    interactor: CoreInteractor(container: dependencies.dependencyContainer)
                )
                onboardingBuilder = OnboardingBuilder(
                    interactor: OnboardingInteractor(container: dependencies.dependencyContainer)
                )

                return true
            }
        }
        """
    }
}

