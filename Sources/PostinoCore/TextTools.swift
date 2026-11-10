import Foundation

public enum TextTools {
    /// Escapes a Swift string so it can sit inside an AppleScript string literal.
    public static func appleScriptLiteral(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    /// Plain text to minimal HTML suitable for a mail body.
    public static func htmlFromPlain(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "<br>")
        return "<div>\(escaped)</div><br>"
    }

    /// Inserts `fragment` right after the opening <body> tag, or prepends it when there is none.
    public static func insertIntoBody(html: String, fragment: String) -> String {
        guard let open = html.range(of: "<body", options: .caseInsensitive),
              let close = html.range(of: ">", range: open.upperBound..<html.endIndex)
        else { return fragment + html }
        var out = html
        out.insert(contentsOf: fragment, at: close.upperBound)
        return out
    }

    /// Cuts very long mail bodies so they fit the model context.
    public static func truncate(_ s: String, limit: Int, lang: Lang = .current) -> String {
        guard limit > 0, s.count > limit else { return s }
        return String(s.prefix(limit)) + "\n" + tr("[... text truncated ...]", "[... testo troncato ...]", lang: lang)
    }

    /// Removes <think>…</think> blocks some local models emit, including an unfinished one.
    public static func stripThinking(_ s: String) -> String {
        var out = s
        while let start = out.range(of: "<think>") {
            if let end = out.range(of: "</think>", range: start.upperBound..<out.endIndex) {
                out.removeSubrange(start.lowerBound..<end.upperBound)
            } else {
                out.removeSubrange(start.lowerBound..<out.endIndex)
            }
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extracts the text delta from one SSE line of an OpenAI-compatible stream.
    /// Returns nil for lines carrying no content (comments, [DONE], role-only chunks).
    public static func deltaFromSSE(line: String) -> String? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        guard payload != "[DONE]", let data = payload.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String
        else { return nil }
        return content
    }

    public static func chatCompletionsURL(base: String) -> URL? {
        var b = base.trimmingCharacters(in: .whitespacesAndNewlines)
        while b.hasSuffix("/") { b.removeLast() }
        if b.hasSuffix("/chat/completions") { return URL(string: b) }
        return URL(string: b + "/chat/completions")
    }
}
