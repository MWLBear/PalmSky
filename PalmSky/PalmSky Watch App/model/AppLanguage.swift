import Foundation

enum AppLanguage: Equatable {
    case zhHans
    case zhHant
    case en
    case other(String)

    static var current: AppLanguage {
        let preferred = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "en"
        let normalized = preferred.lowercased()

        if normalized.contains("zh-hant") { return .zhHant }
        if normalized.contains("zh-hans") { return .zhHans }
        if normalized.hasPrefix("en") { return .en }
        return .other(preferred)
    }

    static var isTraditionalChinese: Bool {
        current == .zhHant
    }
}

