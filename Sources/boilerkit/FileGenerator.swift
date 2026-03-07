import Foundation

// MARK: - FileGenerator

struct FileGenerator {
	// MARK: - Properties

	private let config: ProjectConfig
	private let fileManager = FileManager.default

	// MARK: - Init

	init(config: ProjectConfig) {
		self.config = config
	}

	// MARK: - Generate

	func generate() throws {
		let root = config.outputDirectory.appending("/\(config.appName)")

		print("  ✍️ Creating project structure...")

		try createDirectories(root: root)
		try writeRootFiles(root: root)
		try writeRIBFiles(root: root)
		try writeTabBarFiles(root: root)
		try writeFeatureFiles(root: root)
		try writeComponentsPlaceholder(root: root)

		if config.useSwiftData {
			try writeSwiftDataFiles(root: root)
		}

		if config.useLocalization {
			try writeLocalizationFiles(root: root)
		}

		if config.useDevSettings {
			try writeDevSettingsFiles(root: root)
		}

		try writeAssets(root: root)
		try writeTestFiles(root: root)

		if config.useLinting {
			try writeLintingConfig(root: root)
		}

		if config.useFormatting {
			try writeFormattingConfig(root: root)
		}

		print("  ✅ Source files written")
	}

	// MARK: - Directories

	private func createDirectories(root: String) throws {
		var dirs = [
			root,
			"\(root)/\(config.appName)/Root/RIB",
			"\(root)/\(config.appName)/Components/Extensions",
			"\(root)/\(config.appName)/Components/ViewModifiers",
			"\(root)/\(config.appName)/Components/Views",
			"\(root)/\(config.appName)/Models/Domain",
			"\(root)/\(config.appName)/Models/Entities",
			"\(root)/\(config.appName)/Models/Services",
			"\(root)/\(config.appName)/Assets.xcassets/AppIcon.appiconset",
			"\(root)/\(config.appName)/Assets.xcassets/AccentColor.colorset",
			"\(root)/\(config.appName)Tests/Shared/Mocks",
		]

		let tabDirs = config.tabs.map {
			"\(root)/\(config.appName)/Core/\($0.sanitizedName)"
		}

		if config.tabs.count > 1 {
			dirs.append("\(root)/\(config.appName)/Core/TabBar")
		}

		let devSettingsDirs = config.useDevSettings
			? ["\(root)/\(config.appName)/Core/DevSettings"]
			: []

		for dir in dirs + tabDirs + devSettingsDirs {
			try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
		}
	}

	// MARK: - Root Files

	private func writeRootFiles(root: String) throws {
		let appDir = "\(root)/\(config.appName)/Root"

		try write(
			AppTemplate.render(config: config),
			to: "\(appDir)/\(config.appName)App.swift"
		)
		try write(
			AppDelegateTemplate.render(config: config),
			to: "\(appDir)/AppDelegate.swift"
		)
		try write(
			DependenciesTemplate.render(config: config),
			to: "\(appDir)/Dependencies.swift"
		)
		try write(
			DependencyContainerTemplate.render(),
			to: "\(appDir)/DependencyContainer.swift"
		)
	}

	// MARK: - RIB Files

	private func writeRIBFiles(root: String) throws {
		let ribDir = "\(root)/\(config.appName)/Root/RIB"

		try write(
			BuilderTemplate.render(),
			to: "\(ribDir)/Builder.swift"
		)
		try write(
			CoreBuilderTemplate.render(config: config),
			to: "\(ribDir)/CoreBuilder.swift"
		)
		try write(
			CoreInteractorTemplate.render(config: config),
			to: "\(ribDir)/CoreInteractor.swift"
		)
		try write(
			CoreRouterTemplate.render(config: config),
			to: "\(ribDir)/CoreRouter.swift"
		)
	}

	// MARK: - TabBar Files

	private func writeTabBarFiles(root: String) throws {
		guard config.tabs.count > 1 else { return }
		let tabBarDir = "\(root)/\(config.appName)/Core/TabBar"

		try write(
			TabBarTemplate.render(config: config),
			to: "\(tabBarDir)/TabBarView.swift"
		)
	}

	// MARK: - Feature Files (one per tab)

	private func writeFeatureFiles(root: String) throws {
		for (index, tab) in config.tabs.enumerated() {
			let featureDir = "\(root)/\(config.appName)/Core/\(tab.sanitizedName)"
			try write(
				FeatureViewTemplate.render(
					tab: tab,
					isFirst: index == 0,
					useDevSettings: config.useDevSettings
				),
				to: "\(featureDir)/\(tab.sanitizedName)View.swift"
			)
		}
	}

	// MARK: - Components Placeholder

	private func writeComponentsPlaceholder(root: String) throws {
		let placeholder = """
		// Add reusable extensions here.
		"""
		try write(placeholder, to: "\(root)/\(config.appName)/Components/Extensions/.gitkeep")
	}

	// MARK: - SwiftData Files

	private func writeSwiftDataFiles(root: String) throws {
		guard let entityName = config.swiftDataEntityName else { return }

		let domainDir = "\(root)/\(config.appName)/Models/Domain"
		let entitiesDir = "\(root)/\(config.appName)/Models/Entities"
		let servicesDir = "\(root)/\(config.appName)/Models/Services"

		try write(
			SwiftDataTemplates.renderDomainModel(entityName: entityName),
			to: "\(domainDir)/\(entityName).swift"
		)
		try write(
			SwiftDataTemplates.renderEntity(entityName: entityName),
			to: "\(entitiesDir)/\(entityName)Entity.swift"
		)
		try write(
			SwiftDataTemplates.renderMapper(entityName: entityName),
			to: "\(servicesDir)/\(entityName)Mapper.swift"
		)
		try write(
			SwiftDataTemplates.renderRepository(entityName: entityName),
			to: "\(servicesDir)/\(entityName)Repository.swift"
		)
		try write(
			SwiftDataTemplates.renderManager(entityName: entityName),
			to: "\(servicesDir)/\(entityName)Manager.swift"
		)
	}

	// MARK: - DevSettings Files

	private func writeDevSettingsFiles(root: String) throws {
		let devSettingsDir = "\(root)/\(config.appName)/Core/DevSettings"
		try write(
			DevSettingsTemplate.render(appName: config.appName),
			to: "\(devSettingsDir)/DevSettingsView.swift"
		)
	}

	// MARK: - Localization Files

	private func writeLocalizationFiles(root: String) throws {
		let rootDir = "\(root)/\(config.appName)/Root"

		// Write the String Catalog
		try write(
			StringCatalogTemplate.render(config: config),
			to: "\(rootDir)/Localizable.xcstrings"
		)

		// Create one .lproj directory per selected language (plus en).
		// XcodeGen scans for .lproj dirs to populate knownRegions in the .xcodeproj,
		// which makes all languages appear in Xcode's String Catalog editor.
		let allLanguages = ["en"] + config.localizationLanguages
		for lang in allLanguages {
			let lprojDir = "\(rootDir)/\(lang).lproj"
			try fileManager.createDirectory(atPath: lprojDir, withIntermediateDirectories: true)
		}
	}

	// MARK: - Assets

	private func writeAssets(root: String) throws {
		let assetsDir = "\(root)/\(config.appName)/Assets.xcassets"

		// Root Contents.json
		try write(assetsContentsJSON(), to: "\(assetsDir)/Contents.json")

		// AppIcon
		try write(
			appIconContentsJSON(),
			to: "\(assetsDir)/AppIcon.appiconset/Contents.json"
		)

		// AccentColor
		try write(
			accentColorContentsJSON(),
			to: "\(assetsDir)/AccentColor.colorset/Contents.json"
		)
	}

	private func assetsContentsJSON() -> String {
		"""
		{
		  "info" : {
		    "author" : "xcode",
		    "version" : 1
		  }
		}
		"""
	}

	private func appIconContentsJSON() -> String {
		"""
		{
		  "images" : [
		    {
		      "idiom" : "universal",
		      "platform" : "ios",
		      "size" : "1024x1024"
		    }
		  ],
		  "info" : {
		    "author" : "xcode",
		    "version" : 1
		  }
		}
		"""
	}

	private func accentColorContentsJSON() -> String {
		"""
		{
		  "colors" : [
		    {
		      "idiom" : "universal"
		    }
		  ],
		  "info" : {
		    "author" : "xcode",
		    "version" : 1
		  }
		}
		"""
	}

	// MARK: - Test Files

	private func writeTestFiles(root: String) throws {
		let testsDir = "\(root)/\(config.appName)Tests"

		try write(
			TestTagsTemplate.render(config: config),
			to: "\(testsDir)/Tags.swift"
		)
	}

	// MARK: - SwiftLint Config

	private func writeLintingConfig(root: String) throws {
		let content = """
		excluded:
		  - .build
		  - Packages

		opt_in_rules:
		  - empty_count
		  - closure_spacing
		  - force_unwrapping

		analyzer_rules:
		  - unused_import
		"""
		try write(content, to: "\(root)/.swiftlint.yml")
	}

	// MARK: - SwiftFormat Config

	private func writeFormattingConfig(root: String) throws {
		let content = """
		--swiftversion \(config.swiftVersion)
		--indent 4
		--importgrouping testable-bottom
		--wrapcollections before-first
		"""
		try write(content, to: "\(root)/.swiftformat")
	}

	// MARK: - Write Helper

	private func write(_ content: String, to path: String) throws {
		guard let data = content.data(using: .utf8) else {
			throw GeneratorError.encodingFailed(path)
		}
		fileManager.createFile(atPath: path, contents: data)
	}
}

// MARK: - GeneratorError

enum GeneratorError: Error, CustomStringConvertible {
	case encodingFailed(String)

	var description: String {
		switch self {
		case .encodingFailed(let path):
			return "Failed to encode content for file: \(path)"
		}
	}
}
