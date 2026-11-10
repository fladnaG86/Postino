import AppKit
import PostinoCore

enum Mode { case summary, reply, rewrite }

@MainActor
final class Session: ObservableObject {
    @Published var mode: Mode = .summary
    @Published var mail: Mail?
    @Published var output = ""
    @Published var instructions = ""
    /// Free text typed by the user for the rewrite mode. Kept between openings of the panel.
    @Published var draftText = ""
    @Published var busy = false
    @Published var error: String?
    @Published var notice: String?
    /// True once a reply has been generated at least once for the current mail.
    @Published var replyReady = false

    private var task: Task<Void, Never>?

    func start(_ mode: Mode) {
        cancel()
        self.mode = mode
        output = ""
        error = nil
        notice = nil
        replyReady = false
        instructions = ""
        if mode == .rewrite {
            mail = nil
            return
        }
        do {
            mail = try OutlookBridge.selectedMail()
        } catch {
            mail = nil
            self.error = error.localizedDescription
            return
        }
        if mode == .summary { generate() }
    }

    func switchToReply() {
        cancel()
        mode = .reply
        output = ""
        error = nil
        notice = nil
        replyReady = false
    }

    func generate() {
        let messages: [ChatMessage]
        switch mode {
        case .rewrite:
            let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                error = tr("Type some text to rewrite first.", "Scrivi prima un testo da riscrivere.")
                return
            }
            messages = Prompts.rewrite(text: text, instructions: instructions,
                                       limit: Prefs.bodyLimit, personal: Prefs.personal)
        case .summary:
            guard let mail else { return }
            messages = Prompts.summary(mail: mail, limit: Prefs.bodyLimit, personal: Prefs.personal)
        case .reply:
            guard let mail else { return }
            messages = Prompts.reply(mail: mail, instructions: instructions,
                                     limit: Prefs.bodyLimit, personal: Prefs.personal)
        }
        cancel()
        output = ""
        error = nil
        notice = nil
        busy = true
        let isReply = mode != .summary
        task = Task {
            var raw = ""
            do {
                for try await delta in LLMClient.stream(messages: messages) {
                    raw += delta
                    self.output = TextTools.stripThinking(raw)
                }
                if Task.isCancelled { return }
                if self.output.isEmpty {
                    self.error = tr("The model returned no text.", "Il modello non ha restituito testo.")
                } else if isReply {
                    self.replyReady = true
                }
            } catch is CancellationError {
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
            self.busy = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        busy = false
    }

    func openDraft() {
        guard let mail, !output.isEmpty else { return }
        do {
            try OutlookBridge.openReplyDraft(to: mail.id, text: output, replyAll: Prefs.replyAll)
            notice = tr("Draft opened in Outlook. Review it and send it yourself.",
                        "Bozza aperta in Outlook. Controlla e invia tu.")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        notice = tr("Copied.", "Copiato.")
    }
}
