// MARK: - SwiftDataTemplates

enum SwiftDataTemplates {

    // MARK: - Domain Model

    static func renderDomainModel(entityName: String) -> String {
        """
        import Foundation

        // MARK: - \(entityName)

        struct \(entityName): Identifiable, Equatable {

            // MARK: - Properties

            let id: UUID
            var createdAt: Date

            // MARK: - Init

            init(id: UUID = UUID(), createdAt: Date = Date()) {
                self.id = id
                self.createdAt = createdAt
            }
        }
        """
    }

    // MARK: - Entity

    static func renderEntity(entityName: String) -> String {
        """
        import SwiftData
        import Foundation

        // MARK: - \(entityName)Entity

        @Model
        final class \(entityName)Entity {

            // MARK: - Properties

            var id: UUID
            var createdAt: Date

            // MARK: - Init

            init(id: UUID = UUID(), createdAt: Date = Date()) {
                self.id = id
                self.createdAt = createdAt
            }
        }
        """
    }

    // MARK: - Mapper

    static func renderMapper(entityName: String) -> String {
        """
        import Foundation

        // MARK: - \(entityName)Mapper

        enum \(entityName)Mapper {

            static func toDomain(_ entity: \(entityName)Entity) -> \(entityName) {
                \(entityName)(
                    id: entity.id,
                    createdAt: entity.createdAt
                )
            }

            static func toEntity(_ domain: \(entityName)) -> \(entityName)Entity {
                \(entityName)Entity(
                    id: domain.id,
                    createdAt: domain.createdAt
                )
            }
        }
        """
    }

    // MARK: - Repository

    static func renderRepository(entityName: String) -> String {
        """
        import Foundation
        import SwiftData

        // MARK: - \(entityName)Repository

        @MainActor
        protocol \(entityName)Repository {
            func fetchAll() throws -> [\(entityName)]
            func save(_ item: \(entityName)) throws
            func delete(_ item: \(entityName)) throws
        }

        // MARK: - Mock\(entityName)Repository

        @MainActor
        final class Mock\(entityName)Repository: \(entityName)Repository {

            // MARK: - Properties

            var items: [\(entityName)] = []

            // MARK: - \(entityName)Repository

            func fetchAll() throws -> [\(entityName)] {
                items
            }

            func save(_ item: \(entityName)) throws {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = item
                } else {
                    items.append(item)
                }
            }

            func delete(_ item: \(entityName)) throws {
                items.removeAll { $0.id == item.id }
            }
        }

        // MARK: - SwiftData\(entityName)Repository

        @MainActor
        final class SwiftData\(entityName)Repository: \(entityName)Repository {

            // MARK: - Properties

            private let container: ModelContainer

            // MARK: - Init

            init(container: ModelContainer) {
                self.container = container
            }

            // MARK: - \(entityName)Repository

            func fetchAll() throws -> [\(entityName)] {
                let context = container.mainContext
                let entities = try context.fetch(FetchDescriptor<\(entityName)Entity>())
                return entities.map(\(entityName)Mapper.toDomain)
            }

            func save(_ item: \(entityName)) throws {
                let context = container.mainContext
                let entity = \(entityName)Mapper.toEntity(item)
                context.insert(entity)
                try context.save()
            }

            func delete(_ item: \(entityName)) throws {
                let context = container.mainContext
                let entities = try context.fetch(FetchDescriptor<\(entityName)Entity>())
                if let entity = entities.first(where: { $0.id == item.id }) {
                    context.delete(entity)
                    try context.save()
                }
            }
        }
        """
    }

    // MARK: - Manager

    static func renderManager(entityName: String) -> String {
        """
        import Foundation

        // MARK: - \(entityName)Manager

        @MainActor
        final class \(entityName)Manager {

            // MARK: - Properties

            private let repository: any \(entityName)Repository

            // MARK: - Init

            init(repository: any \(entityName)Repository) {
                self.repository = repository
            }

            // MARK: - Methods

            func fetchAll() throws -> [\(entityName)] {
                try repository.fetchAll()
            }

            func save(_ item: \(entityName)) throws {
                try repository.save(item)
            }

            func delete(_ item: \(entityName)) throws {
                try repository.delete(item)
            }
        }
        """
    }
}
