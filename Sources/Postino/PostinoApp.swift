import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct PostinoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Postino", systemImage: "envelope.badge") {
            Button("Riassumi mail selezionata  ⌃⌥S") { delegate.run(.summary) }
            Button("Rispondi alla mail selezionata  ⌃⌥R") { delegate.run(.reply) }
            Divider()
            Button("Impostazioni…") { delegate.showSettings() }
            Button("Esci") { NSApp.terminate(nil) }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let session = Session()
    private var panel: NSPanel?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let mods = controlKey | optionKey
        HotKeys.register(id: 1, keyCode: kVK_ANSI_S, modifiers: mods) { [weak self] in self?.run(.summary) }
        HotKeys.register(id: 2, keyCode: kVK_ANSI_R, modifiers: mods) { [weak self] in self?.run(.reply) }
    }

    func run(_ mode: Mode) {
        session.start(mode)
        showPanel()
    }

    private func showPanel() {
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
                            styleMask: [.titled, .closable, .resizable, .utilityWindow],
                            backing: .buffered, defer: false)
            p.title = "Postino"
            p.isFloatingPanel = true
            p.level = .floating
            p.hidesOnDeactivate = false
            p.isReleasedWhenClosed = false
            p.contentView = NSHostingView(rootView: ResultView(session: session))
            p.center()
            p.setFrameAutosaveName("PostinoPanel")
            panel = p
        }
        NSApp.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }

    func showSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.title = "Impostazioni Postino"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: SettingsView())
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
