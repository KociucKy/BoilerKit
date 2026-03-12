// MARK: - DevSettingsTemplate

enum DevSettingsTemplate {

    // MARK: - Interactor

    static func renderInteractor() -> String {
        """
        import Foundation
        import NavigationKit

        // MARK: - DevSettingsInteractor

        @MainActor
        protocol DevSettingsInteractor {
            // TODO: Define DevSettings interactor methods
        }

        extension CoreInteractor: DevSettingsInteractor {}
        """
    }

    // MARK: - Router

    static func renderRouter() -> String {
        """
        import Foundation
        import NavigationKit

        // MARK: - DevSettingsRouter

        @MainActor
        protocol DevSettingsRouter {
            func dismissDevSettings()
        }

        extension CoreRouter: DevSettingsRouter {}
        """
    }

    // MARK: - Presenter

    static func renderPresenter() -> String {
        """
        import Foundation

        // MARK: - DevSettingsPresenter

        @Observable
        @MainActor
        final class DevSettingsPresenter {

            // MARK: - Properties

            private let interactor: any DevSettingsInteractor
            private let router: any DevSettingsRouter

            // MARK: - Init

            init(interactor: any DevSettingsInteractor, router: any DevSettingsRouter) {
                self.interactor = interactor
                self.router = router
            }

            // MARK: - Actions

            func dismiss() {
                router.dismissDevSettings()
            }
        }
        """
    }

    // MARK: - View

    static func renderView() -> String {
        """
        import SwiftUI
        import NavigationKit

        // MARK: - DevSettingsView

        struct DevSettingsView: View {

            // MARK: - Properties

            @State var presenter: DevSettingsPresenter

            // MARK: - Body

            var body: some View {
                Text("Dev Settings")
                    .navigationTitle("Dev Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                presenter.dismiss()
                            }
                        }
                    }
            }
        }

        // MARK: - Preview

        #Preview {
            let container = DevPreview.shared.container
            let builder = CoreBuilder(interactor: CoreInteractor(container: container))

            return RouterView { router in
                builder.devSettingsView(router: router)
            }
        }
        """
    }
}
