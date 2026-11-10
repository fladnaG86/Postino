import SwiftUI

struct ResultView: View {
    @ObservedObject var session: Session
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
                Text(session.mode == .summary ? "Riassunto" : "Bozza di risposta").font(.headline)
                if session.busy { ProgressView().controlSize(.small) }
                Spacer()
            }
            if let mail = session.mail {
                Text(mail.subject.isEmpty ? "(senza oggetto)" : mail.subject).lineLimit(1)
                Text(mail.senderName.isEmpty ? mail.senderAddress : "\(mail.senderName) <\(mail.senderAddress)>")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    private var instructionsRow: some View {
        HStack {
            TextField("Indicazioni (facoltative): es. accetta e proponi giovedì", text: $session.instructions)
                .textFieldStyle(.roundedBorder)
                .focused($instructionsFocused)
                .onSubmit { session.generate() }
            Button(session.replyReady ? "Rigenera" : "Genera") { session.generate() }
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
                Text("Il modello sta ragionando…").foregroundStyle(.secondary)
            }
        }
    }

    private var buttons: some View {
        HStack {
            if session.busy {
                Button("Ferma") { session.cancel() }
            }
            Spacer()
            Button("Copia") { session.copy() }.disabled(session.output.isEmpty)
            if session.mode == .summary {
                Button("Rispondi…") { session.switchToReply() }.disabled(session.mail == nil)
            } else {
                Button("Apri bozza in Outlook") { session.openDraft() }
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
    @State private var apiKey = KeychainStore.read()
    @State private var saved = false

    var body: some View {
        Form {
            Section("Modello") {
                TextField("Endpoint (OpenAI-compatibile)", text: $baseURL)
                TextField("Modello", text: $model)
                SecureField("Chiave API (vuota per LLM locale)", text: $apiKey)
                HStack {
                    Button("Salva chiave nel Portachiavi") { saved = KeychainStore.write(apiKey) }
                    if saved { Text("Salvata").foregroundStyle(.secondary) }
                }
                Text("Locale: http://127.0.0.1:8001/v1 (llama.cpp) o http://127.0.0.1:11434/v1 (Ollama). Con un endpoint remoto il testo delle mail esce dal Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Risposte") {
                Toggle("Rispondi a tutti", isOn: $replyAll)
                TextField("Preferenze personali (tono, firma…)", text: $personal, axis: .vertical)
                    .lineLimit(2...5)
                Stepper("Massimo caratteri mail inviati al modello: \(bodyLimit)",
                        value: $bodyLimit, in: 2000...60000, step: 2000)
            }
            Section("Scorciatoie") {
                Text("⌃⌥S  Riassumi mail selezionata\n⌃⌥R  Rispondi alla mail selezionata")
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 520)
    }
}
