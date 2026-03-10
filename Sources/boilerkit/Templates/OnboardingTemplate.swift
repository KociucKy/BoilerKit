// MARK: - OnboardingTemplate

enum OnboardingTemplate {

    // MARK: - OnboardingBuilder

    static func renderBuilder(appName: String) -> String {
        """
        import SwiftUI
        import NavigationKit

        // MARK: - OnboardingBuilder

        @MainActor
        struct OnboardingBuilder: Builder {

            // MARK: - Properties

            let interactor: OnboardingInteractor

            // MARK: - Builder

            func build() -> AnyView {
                welcomeView().any()
            }

            // MARK: - Views

            func welcomeView() -> some View {
                RouterView { router in
                    WelcomeView(
                        presenter: WelcomePresenter(
                            interactor: interactor,
                            router: OnboardingRouter(router: router, builder: self)
                        )
                    )
                }
            }

            func onboardingCompletedView(router: Router) -> some View {
                OnboardingCompletedView(
                    presenter: OnboardingCompletedPresenter(
                        interactor: interactor,
                        router: OnboardingRouter(router: router, builder: self)
                    )
                )
            }
        }
        """
    }

    // MARK: - OnboardingInteractor

    static func renderInteractor() -> String {
        """
        import Foundation

        // MARK: - OnboardingInteractor

        @MainActor
        struct OnboardingInteractor {

            // MARK: - Properties

            private let appState: AppState

            // MARK: - Init

            init(container: DependencyContainer) {
                self.appState = container.resolve(AppState.self)!
            }

            // MARK: - App State

            func completeOnboarding() {
                appState.updateViewState(showOnboarding: false)
            }
        }
        """
    }

    // MARK: - OnboardingRouter

    static func renderRouter() -> String {
        """
        import Foundation
        import NavigationKit

        // MARK: - OnboardingRouter

        @MainActor
        struct OnboardingRouter: GlobalRouter {

            // MARK: - Properties

            let router: Router
            let builder: OnboardingBuilder

            // MARK: - Navigation

            func showOnboardingCompletedView() {
                router.showScreen(.push) { router in
                    builder.onboardingCompletedView(router: router)
                }
            }
        }
        """
    }

    // MARK: - WelcomeView

    static func renderWelcomeView(appName: String) -> String {
        """
        import SwiftUI

        // MARK: - WelcomeView

        struct WelcomeView: View {

            // MARK: - Properties

            @State var presenter: WelcomePresenter

            // MARK: - Body

            var body: some View {
                VStack(spacing: 16) {
                    Spacer()
                    titleSection
                    Spacer()
                    getStartedButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .navigationBarHidden(true)
            }

            // MARK: - Title Section

            private var titleSection: some View {
                VStack(spacing: 8) {
                    Text("\(appName)")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    Text("Get started to set up your profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            // MARK: - Get Started Button

            private var getStartedButton: some View {
                Button {
                    presenter.onGetStartedPressed()
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        """
    }

    // MARK: - WelcomePresenter

    static func renderWelcomePresenter() -> String {
        """
        import Foundation

        // MARK: - WelcomePresenter

        @Observable
        @MainActor
        final class WelcomePresenter {

            // MARK: - Properties

            private let interactor: OnboardingInteractor
            private let router: OnboardingRouter

            // MARK: - Init

            init(interactor: OnboardingInteractor, router: OnboardingRouter) {
                self.interactor = interactor
                self.router = router
            }

            // MARK: - Actions

            func onGetStartedPressed() {
                router.showOnboardingCompletedView()
            }
        }
        """
    }

    // MARK: - OnboardingCompletedView

    static func renderCompletedView() -> String {
        """
        import SwiftUI

        // MARK: - OnboardingCompletedView

        struct OnboardingCompletedView: View {

            // MARK: - Properties

            @State var presenter: OnboardingCompletedPresenter

            // MARK: - Body

            var body: some View {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Setup complete!")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    Text("You're all set and ready to go.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(24)
                .safeAreaInset(edge: .bottom) {
                    finishButton
                        .padding(24)
                }
                .navigationBarHidden(true)
            }

            // MARK: - Finish Button

            private var finishButton: some View {
                Button {
                    presenter.onFinishButtonPressed()
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        """
    }

    // MARK: - OnboardingCompletedPresenter

    static func renderCompletedPresenter() -> String {
        """
        import Foundation

        // MARK: - OnboardingCompletedPresenter

        @Observable
        @MainActor
        final class OnboardingCompletedPresenter {

            // MARK: - Properties

            private let interactor: OnboardingInteractor
            private let router: OnboardingRouter

            // MARK: - Init

            init(interactor: OnboardingInteractor, router: OnboardingRouter) {
                self.interactor = interactor
                self.router = router
            }

            // MARK: - Actions

            func onFinishButtonPressed() {
                interactor.completeOnboarding()
            }
        }
        """
    }
}
