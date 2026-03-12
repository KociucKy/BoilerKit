// MARK: - FeatureViewTemplate

enum FeatureViewTemplate {

    // MARK: - Interactor

    static func renderInteractor(tab: Tab) -> String {
        let feature = tab.sanitizedName
        return """
        import Foundation
        import NavigationKit

        // MARK: - \(feature)Interactor

        @MainActor
        protocol \(feature)Interactor {
            // TODO: Define \(feature) interactor methods
        }

        extension CoreInteractor: \(feature)Interactor {}
        """
    }

    // MARK: - Router

    static func renderRouter(tab: Tab, isFirst: Bool, useDevSettings: Bool) -> String {
        let feature = tab.sanitizedName
        let devSettingsRouterMethod = useDevSettings && isFirst
            ? "\n    func presentDevSettings()"
            : ""
        return """
        import Foundation
        import NavigationKit

        // MARK: - \(feature)Router

        @MainActor
        protocol \(feature)Router {
            func dismissScreen()\(devSettingsRouterMethod)
        }

        extension CoreRouter: \(feature)Router {}
        """
    }

    // MARK: - Presenter

    static func renderPresenter(tab: Tab, isFirst: Bool, useDevSettings: Bool) -> String {
        let feature = tab.sanitizedName
        let devSettingsPresenterMethod = useDevSettings && isFirst ? """


            // MARK: - Dev Settings

            func showDevSettings() {
                router.presentDevSettings()
            }
        """ : ""
        return """
        import Foundation

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
        """
    }

    // MARK: - View

    static func renderView(tab: Tab, isFirst: Bool, useDevSettings: Bool) -> String {
        let feature = tab.sanitizedName
        let featureLower = feature.lowercased()

        if useDevSettings && isFirst {
            return """
            import SwiftUI
            import NavigationKit

            // MARK: - \(feature)View

            struct \(feature)View: View {

                // MARK: - Properties

                @State var presenter: \(feature)Presenter

                // MARK: - Body

                var body: some View {
                    Text("\(feature)")
                        .navigationTitle("\(feature)")
                        .toolbar {
                            #if DEBUG
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    presenter.showDevSettings()
                                } label: {
                                    Image(systemName: "hammer.fill")
                                }
                            }
                            #endif
                        }
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
        } else {
            return """
            import SwiftUI
            import NavigationKit

            // MARK: - \(feature)View

            struct \(feature)View: View {

                // MARK: - Properties

                @State var presenter: \(feature)Presenter

                // MARK: - Body

                var body: some View {
                    Text("\(feature)")
                        .navigationTitle("\(feature)")
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
}
