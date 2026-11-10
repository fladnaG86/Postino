import Foundation
import PostinoCore

struct BridgeError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Talks to Outlook through Apple Events. All calls run on the main thread (NSAppleScript requirement).
@MainActor
enum OutlookBridge {
    private static func run(_ source: String) throws -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else {
            throw BridgeError(message: "Script non valido")
        }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let err {
            let code = err[NSAppleScript.errorNumber] as? Int ?? 0
            let msg = err[NSAppleScript.errorMessage] as? String ?? "Errore AppleScript"
            if code == -1743 {
                throw BridgeError(message: "Permesso negato. Abilita Postino in Impostazioni di Sistema → Privacy e sicurezza → Automazione → Microsoft Outlook.")
            }
            if code == -600 { throw BridgeError(message: "Outlook non è aperto.") }
            throw BridgeError(message: msg)
        }
        return result
    }

    static func selectedMail() throws -> Mail {
        let d = try run("""
        tell application "Microsoft Outlook"
            set sel to selected objects
            if (count of sel) is 0 then error "Nessuna mail selezionata in Outlook."
            set m to item 1 of sel
            set k to class of m
            if k is not incoming message and k is not outgoing message and k is not message then error "L'elemento selezionato non è una mail."
            set sName to ""
            set sAddr to ""
            try
                set s to sender of m
                try
                    set sName to name of s
                end try
                try
                    set sAddr to address of s
                end try
            end try
            return {id of m, (get subject of m), sName, sAddr, (get plain text content of m)}
        end tell
        """)
        guard d.numberOfItems == 5 else { throw BridgeError(message: "Risposta inattesa da Outlook.") }
        func text(_ i: Int) -> String { d.atIndex(i)?.stringValue ?? "" }
        return Mail(id: Int(d.atIndex(1)?.int32Value ?? 0), subject: text(2),
                    senderName: text(3), senderAddress: text(4), body: text(5))
    }

    /// Creates a reply draft, writes `text` above the quoted mail and opens the draft window.
    /// Never sends anything.
    static func openReplyDraft(to mailID: Int, text: String, replyAll: Bool) throws {
        let created = try run("""
        tell application "Microsoft Outlook"
            set r to reply to (message id \(mailID)) without opening window\(replyAll ? " with reply to all" : "")
            return {id of r, (get content of r)}
        end tell
        """)
        guard created.numberOfItems == 2, let draftID = created.atIndex(1)?.int32Value else {
            throw BridgeError(message: "Outlook non ha creato la bozza.")
        }
        let quoted = created.atIndex(2)?.stringValue ?? ""
        let html = TextTools.insertIntoBody(html: quoted, fragment: TextTools.htmlFromPlain(text))
        _ = try run("""
        tell application "Microsoft Outlook"
            set content of message id \(draftID) to \(TextTools.appleScriptLiteral(html))
            open message id \(draftID)
            activate
        end tell
        """)
    }
}
