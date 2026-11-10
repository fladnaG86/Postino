import Foundation
import PostinoCore

struct LLMError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum LLMClient {
    /// Streams text deltas from an OpenAI-compatible /chat/completions endpoint.
    static func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = TextTools.chatCompletionsURL(base: Prefs.baseURL) else {
                        throw LLMError(message: tr("Invalid endpoint URL", "URL endpoint non valido") + ": \(Prefs.baseURL)")
                    }
                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.timeoutInterval = 300
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let key = KeychainStore.read()
                    if !key.isEmpty { req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
                    let body: [String: Any] = [
                        "model": Prefs.model,
                        "stream": true,
                        "temperature": 0.3,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else {
                        throw LLMError(message: tr("Non-HTTP response", "Risposta non HTTP"))
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var detail = ""
                        for try await line in bytes.lines {
                            detail += line
                            if detail.count > 400 { break }
                        }
                        throw LLMError(message: "HTTP \(http.statusCode) \(tr("from", "da")) \(url.host ?? "?"): \(detail)")
                    }
                    for try await line in bytes.lines {
                        if let delta = TextTools.deltaFromSSE(line: line) { continuation.yield(delta) }
                    }
                    continuation.finish()
                } catch let e as URLError where e.code == .cannotConnectToHost || e.code == .timedOut {
                    continuation.finish(throwing: LLMError(
                        message: tr("Model not reachable at \(Prefs.baseURL). Is the LLM server running?",
                                    "Modello non raggiungibile su \(Prefs.baseURL). Server LLM acceso?")))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
