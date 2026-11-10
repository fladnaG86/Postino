import Foundation

/// Interface language. Follows the system unless the user picks one in Settings.
public enum Lang: String {
    case en, it

    public static let defaultsKey = "language"

    public static var current: Lang {
        switch UserDefaults.standard.string(forKey: defaultsKey) {
        case "it": return .it
        case "en": return .en
        default: return from(preferred: Locale.preferredLanguages)
        }
    }

    public static func from(preferred: [String]) -> Lang {
        (preferred.first ?? "en").lowercased().hasPrefix("it") ? .it : .en
    }
}

/// Picks the string for the active language.
public func tr(_ en: String, _ it: String, lang: Lang = .current) -> String {
    lang == .it ? it : en
}
