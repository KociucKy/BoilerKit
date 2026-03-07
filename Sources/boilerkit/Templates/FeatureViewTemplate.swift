// MARK: - FeatureViewTemplate

enum FeatureViewTemplate {
    static func render(tab: Tab, isFirst: Bool, useDevSettings: Bool) -> String {
        let feature = tab.sanitizedName
        let featureLower = feature.lowercased()
        let devSettingsRouterMethod = useDevSettings && isFirst
            ? "\n            func presentDevSettings()"
            : ""
        let devSettingsPresenterMethod = useDevSettings && isFirst ? """


                    // MARK: - Dev Settings

                    func showDevSettings() {
                        router.presentDevSettings()
                    }
            """ : ""
        let devSettingsToolbar = useDevSettings && isFirst ? """

                    #if DEBUG
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                presenter.showDevSettings()
                            } label: {
                                Image(systemName: "hammer.fill")
                            }
                        }
                    }
                    #endif
            """ : ""

        return """
        import SwiftUI
        import NavigationKit

        // MARK: - \(feature)Interactor

        @MainActor
        protocol \(feature)Interactor {
            // TODO: Define \(feature) interactor methods
        }

        extension CoreInteractor: \(feature)Interactor {}

        // MARK: - \(feature)Router

        @MainActor
        protocol \(feature)Router {
            func dismissScreen()\(devSettingsRouterMethod)
        }

        extension CoreRouter: \(feature)Router {}

        // MARK: - \(feature)Presenter

        @Observable
        @MainActor
        final class \(feature)Presenter {

            // MARK: - Properties

            private let interactor: any \(feature)Interactor
            private let router: any \(feature)Router

            // MARK: - Init

            init(interactor: any \(feature)Interactor, router: any \(feature)Router) {
                self.interactor = interactor
                self.router = router
            }\(devSettingsPresenterMethod)
        }

        // MARK: - \(feature)View

        struct \(feature)View: View {

            // MARK: - Properties

            @State var presenter: \(feature)Presenter

            // MARK: - Body

            var body: some View {
                Text("\(feature)")
                    .navigationTitle("\(feature)")\(devSettingsToolbar)
            }
        }

        // MARK: - Preview

        #Preview {
            let container = DevPreview.shared.container
            let builder = CoreBuilder(interactor: CoreInteractor(container: container))

            return RouterView { router in
                builder.\(featureLower)View(router: router)
            }
        }
        """
    }
}
