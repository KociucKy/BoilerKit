// MARK: - StringCatalogTemplate

enum StringCatalogTemplate {

    static func render(config: ProjectConfig) -> String {
        let allLanguages = ["en"] + config.localizationLanguages

        let localizations = allLanguages
            .map { renderLocalization(code: $0, appName: config.appName) }
            .joined(separator: ",\n")

        return """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "app_name" : {
              "extractionState" : "manual",
              "localizations" : {
        \(localizations)
              }
            }
          },
          "version" : "1.0"
        }
        """
    }

    private static func renderLocalization(code: String, appName: String) -> String {
        let isBase = code == "en"
        let state = isBase ? "translated" : "needs_review"
        let value = isBase ? appName : ""

        return """
                "\(code)" : {
                  "stringUnit" : {
                    "state" : "\(state)",
                    "value" : "\(value)"
                  }
                }
        """
    }
}
