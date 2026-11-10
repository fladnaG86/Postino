import Foundation
import Security

enum PrefKey {
    static let baseURL = "baseURL"
    static let model = "model"
    static let personal = "personal"
    static let bodyLimit = "bodyLimit"
    static let replyAll = "replyAll"
    static let language = "language"
}

enum Prefs {
    static let defaultBaseURL = "http://127.0.0.1:8001/v1"
    static let defaultModel = "gemma-4-26b-a4b"
    static let defaultBodyLimit = 12000

    private static var d: UserDefaults { .standard }

    static var baseURL: String { d.string(forKey: PrefKey.baseURL) ?? defaultBaseURL }
    static var model: String { d.string(forKey: PrefKey.model) ?? defaultModel }
    static var personal: String { d.string(forKey: PrefKey.personal) ?? "" }
    static var replyAll: Bool { d.bool(forKey: PrefKey.replyAll) }
    static var bodyLimit: Int {
        let v = d.integer(forKey: PrefKey.bodyLimit)
        return v > 0 ? v : defaultBodyLimit
    }
}

/// API key lives in the login Keychain, never in UserDefaults.
enum KeychainStore {
    private static let service = "it.postino.apikey"
    private static let account = "default"

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func read() -> String {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    @discardableResult
    static func write(_ value: String) -> Bool {
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return true }
        var q = query
        q[kSecValueData as String] = Data(value.utf8)
        return SecItemAdd(q as CFDictionary, nil) == errSecSuccess
    }
}
