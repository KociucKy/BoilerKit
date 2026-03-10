// MARK: - AppStateTemplate

enum AppStateTemplate {
    static func render() -> String {
        """
        import SwiftUI

        // MARK: - AppState

        @Observable
        final class AppState {

            // MARK: - Properties

            private(set) var showOnboarding: Bool {
                didSet {
                    UserDefaults.showOnboarding = showOnboarding
                }
            }

            // MARK: - Init

            init(showOnboarding: Bool = UserDefaults.showOnboarding) {
                self.showOnboarding = showOnboarding
            }

            // MARK: - Update

            func updateViewState(showOnboarding: Bool) {
                self.showOnboarding = showOnboarding
            }
        }

        // MARK: - UserDefaults

        private extension UserDefaults {
            private struct Keys {
                static let showOnboarding = "showOnboarding"
            }

            static var showOnboarding: Bool {
                get { standard.object(forKey: Keys.showOnboarding) as? Bool ?? true }
                set { standard.set(newValue, forKey: Keys.showOnboarding) }
            }
        }
        """
    }
}
