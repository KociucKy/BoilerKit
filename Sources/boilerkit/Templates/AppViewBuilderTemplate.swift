// MARK: - AppViewBuilderTemplate

enum AppViewBuilderTemplate {
    static func render() -> String {
        """
        import SwiftUI

        // MARK: - AppViewBuilder

        struct AppViewBuilder<MainView: View, OnboardingView: View>: View {

            // MARK: - Properties

            var showOnboarding: Bool
            var mainView: () -> MainView
            var onboardingView: () -> OnboardingView

            // MARK: - Body

            var body: some View {
                ZStack {
                    if showOnboarding {
                        onboardingView()
                            .transition(.move(edge: .leading))
                    } else {
                        mainView()
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.smooth, value: showOnboarding)
            }
        }
        """
    }
}
