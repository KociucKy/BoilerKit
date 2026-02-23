// MARK: - FeatureViewTemplate

enum FeatureViewTemplate {
    static func render(tab: Tab) -> String {
        let feature = tab.sanitizedName

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
            func dismissScreen()
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
            }
        }

        // MARK: - \(feature)View

        struct \(feature)View: View {

            // MARK: - Properties

            @State var presenter: \(feature)Presenter

            // MARK: - Body

            var body: some View {
                NavigationStack {
                    Text("\(feature)")
                        .navigationTitle("\(feature)")
                }
            }
        }

        // MARK: - Preview

        #Preview {
            RouterView { router in
                let interactor = PreviewContainer.shared.coreInteractor
                let coreRouter = CoreRouter(router: router)
                let presenter = \(feature)Presenter(interactor: interactor, router: coreRouter)
                \(feature)View(presenter: presenter)
            }
        }
        """
    }
}
