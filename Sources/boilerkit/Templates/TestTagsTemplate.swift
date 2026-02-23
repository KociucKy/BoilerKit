// MARK: - TestTagsTemplate

enum TestTagsTemplate {
    static func render(config: ProjectConfig) -> String {
        let featureTags = config.tabs
            .map { "    @Tag static var \($0.sanitizedName.lowercased()): Self" }
            .joined(separator: "\n")

        return """
        import Testing

        // MARK: - Tags

        extension Tag {

            // MARK: - Feature Tags

        \(featureTags)

            // MARK: - Behavior Tags

            @Tag static var adding: Self
            @Tag static var deleting: Self
            @Tag static var editing: Self
            @Tag static var navigation: Self

            // MARK: - Priority Tags

            @Tag static var critical: Self
            @Tag static var slow: Self
        }
        """
    }
}
