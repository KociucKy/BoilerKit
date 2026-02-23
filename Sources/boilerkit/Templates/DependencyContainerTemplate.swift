// MARK: - DependencyContainerTemplate

enum DependencyContainerTemplate {
    static func render() -> String {
        """
        import Foundation

        // MARK: - DependencyContainer

        @MainActor
        final class DependencyContainer {

            // MARK: - Properties

            private var factories: [ObjectIdentifier: () -> Any] = [:]

            // MARK: - Registration

            func register<T>(_ type: T.Type, factory: @escaping () -> T) {
                factories[ObjectIdentifier(type)] = factory
            }

            // MARK: - Resolution

            func resolve<T>(_ type: T.Type) -> T {
                guard let factory = factories[ObjectIdentifier(type)] else {
                    fatalError("No registration found for type \\(type). Did you forget to register it in Dependencies?")
                }
                guard let resolved = factory() as? T else {
                    fatalError("Failed to cast resolved instance to \\(type).")
                }
                return resolved
            }
        }
        """
    }
}
