// MARK: - DependencyContainerTemplate

enum DependencyContainerTemplate {
    static func render() -> String {
        """
        import Foundation

        // MARK: - DependencyContainer

        @Observable
        @MainActor
        final class DependencyContainer {

            // MARK: - Properties

            private var services: [String: Any] = [:]

            // MARK: - Registration

            func register<T>(_ type: T.Type, service: T) {
                let key = "\\(type)"
                services[key] = service
            }

            func register<T>(_ type: T.Type, service: () -> T) {
                let key = "\\(type)"
                services[key] = service()
            }

            // MARK: - Resolution

            func resolve<T>(_ type: T.Type) -> T? {
                let key = "\\(type)"
                return services[key] as? T
            }
        }
        """
    }
}
