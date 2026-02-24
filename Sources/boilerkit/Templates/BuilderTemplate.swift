// MARK: - BuilderTemplate

enum BuilderTemplate {
    static func render() -> String {
        """
        import SwiftUI

        // MARK: - Builder

        @MainActor
        protocol Builder {
            func build() -> AnyView
        }
        """
    }
}
