import PostinoCore
import SwiftUI

struct ResultView: View {
    @ObservedObject var session: Session
    /// Read only to redraw when the language changes.
    @AppStorage(PrefKey.language) private var language = "auto"
    @FocusState private var instructionsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if session.mode == .reply && session.mail != nil { instructionsRow }
            content
            if let error = session.error {
                Text(error).foregroundStyle(.red).font(.callout).textSelection(.enabled)
            }
            if let notice = session.notice {
                Text(notice).foregroundStyle(.secondary).font(.callout)
            }
            buttons
        }
        .padding(14)
        .frame(minWidth: 460, minHeight: 360)
        .onChange(of: session.mode) { _, mode in instructionsFocused = mode == .reply }
        .onAppear { instructionsFocused = session.mode == .reply }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(session.mode == .summary ? tr("Summary", "Riassunto") : tr("Reply draft", "Bozza di risposta")).font(.headline)
                if session.busy { ProgressView().controlSize(.small) }
                Spacer()
            }
            if let mail = session.mail {
                Text(mail.subject.isEmpty ? tr("(no subject)", "(senza oggetto)") : mail.subject).lineLimit(1)
                Text(mail.senderName.isEmpty ? mail.senderAddress : "\(mail.senderName) <\(mail.senderAddress)>")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    private var instructionsRow: some View {
        HStack {
            TextField(tr("Directions (optional): e.g. accept and propose Thursday",
                         "Indicazioni (facoltative): es. accetta e proponi giovedì"), text: $session.instructions)
                .textFieldStyle(.roundedBorder)
                .focused($instructionsFocused)
                .onSubmit { session.generate() }
            Button(session.replyReady ? tr("Regenerate", "Rigenera") : tr("Generate", "Genera")) { session.generate() }
                .keyboardShortcut(.defaultAction)
                .disabled(session.busy)
        }
    }

    private var content: some View {
        Group {
            if session.mode == .reply {
                TextEditor(text: $session.output)
                    .font(.body)
                    .disabled(session.busy)
            } else {
                ScrollView {
                    Text(session.output)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
        .overlay {
            if session.busy && session.output.isEmpty {
                Text(tr("The model is thinking…", "Il modello sta ragionando…")).foregroundStyle(.secondary)
            }
        }
    }

    private var buttons: some View {
        HStack {
            if session.busy {
                Button(tr("Stop", "Ferma")) { session.cancel() }
            }
            Spacer()
            Button(tr("Copy", "Copia")) { session.copy() }.disabled(session.output.isEmpty)
            if session.mode == .summary {
                Button(tr("Reply…", "Rispondi…")) { session.switchToReply() }.disabled(session.mail == nil)
            } else {
                Button(tr("Open draft in Outlook", "Apri bozza in Outlook")) { session.openDraft() }
                    .disabled(!session.replyReady || session.busy || session.output.isEmpty)
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage(PrefKey.baseURL) private var baseURL = Prefs.defaultBaseURL
    @AppStorage(PrefKey.model) private var model = Prefs.defaultModel
    @AppStorage(PrefKey.personal) private var personal = ""
    @AppStorage(PrefKey.bodyLimit) private var bodyLimit = Prefs.defaultBodyLimit
    @AppStorage(PrefKey.replyAll) private var replyAll = false
    @AppStorage(PrefKey.language) private var language = "auto"
    @State private var apiKey = KeychainStore.read()
    @State private var saved = false

    var body: some View {
        Form {
            Section(tr("Model", "Modello")) {
                TextField(tr("Endpoint (OpenAI-compatible)", "Endpoint (OpenAI-compatibile)"), text: $baseURL)
                TextField(tr("Model", "Modello"), text: $model)
                SecureField(tr("API key (empty for a local LLM)", "Chiave API (vuota per LLM locale)"), text: $apiKey)
                HStack {
                    Button(tr("Save key to Keychain", "Salva chiave nel Portachiavi")) { saved = KeychainStore.write(apiKey) }
                    if saved { Text(tr("Saved", "Salvata")).foregroundStyle(.secondary) }
                }
                Text(tr("Local: http://127.0.0.1:8001/v1 (llama.cpp) or http://127.0.0.1:11434/v1 (Ollama). With a remote endpoint the mail text leaves your Mac.",
                        "Locale: http://127.0.0.1:8001/v1 (llama.cpp) o http://127.0.0.1:11434/v1 (Ollama). Con un endpoint remoto il testo delle mail esce dal Mac."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(tr("Replies", "Risposte")) {
                Toggle(tr("Reply to all", "Rispondi a tutti"), isOn: $replyAll)
                TextField(tr("Personal preferences (tone, signature…)", "Preferenze personali (tono, firma…)"),
                          text: $personal, axis: .vertical)
                    .lineLimit(2...5)
                Stepper(tr("Maximum mail characters sent to the model", "Massimo caratteri mail inviati al modello") + ": \(bodyLimit)",
                        value: $bodyLimit, in: 2000...60000, step: 2000)
            }
            Section(tr("Language", "Lingua")) {
                Picker(tr("Interface and summaries", "Interfaccia e riassunti"), selection: $language) {
                    Text(tr("System", "Sistema")).tag("auto")
                    Text("English").tag("en")
                    Text("Italiano").tag("it")
                }
                Text(tr("Replies are always written in the language of the received mail.",
                        "Le risposte sono sempre scritte nella lingua della mail ricevuta."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(tr("Shortcuts", "Scorciatoie")) {
                Text("⌃⌥S  " + tr("Summarize selected mail", "Riassumi mail selezionata")
                     + "\n⌃⌥R  " + tr("Reply to selected mail", "Rispondi alla mail selezionata"))
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 620)
    }
}
