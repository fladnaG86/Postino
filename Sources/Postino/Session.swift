import AppKit
import PostinoCore

enum Mode { case summary, reply }

@MainActor
final class Session: ObservableObject {
    @Published var mode: Mode = .summary
    @Published var mail: Mail?
    @Published var output = ""
    @Published var instructions = ""
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
        guard let mail else { return }
        cancel()
        output = ""
        error = nil
        notice = nil
        busy = true
        let messages = mode == .summary
            ? Prompts.summary(mail: mail, limit: Prefs.bodyLimit, personal: Prefs.personal)
            : Prompts.reply(mail: mail, instructions: instructions, limit: Prefs.bodyLimit, personal: Prefs.personal)
        let isReply = mode == .reply
        task = Task {
            var raw = ""
            do {
                for try await delta in LLMClient.stream(messages: messages) {
                    raw += delta
                    self.output = TextTools.stripThinking(raw)
                }
                if Task.isCancelled { return }
                if self.output.isEmpty {
                    self.error = "Il modello non ha restituito testo."
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
            notice = "Bozza aperta in Outlook. Controlla e invia tu."
        } catch {
            self.error = error.localizedDescription
        }
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        notice = "Copiato."
    }
}
