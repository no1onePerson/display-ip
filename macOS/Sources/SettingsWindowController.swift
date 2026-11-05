import AppKit
import SwiftUI

/// The menu bar panel closes in the same turn as the gear click. A window
/// ordered front during that turn is dismissed with the panel, so the real
/// presentation waits until the panel has resigned.
@MainActor enum SettingsOpener {
    static func open(model: PrismModel) {
        SettingsWindowController.shared.prepare(model: model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let app = NSApplication.shared
            app.setActivationPolicy(.regular)
            app.activate(ignoringOtherApps: true)
            SettingsWindowController.shared.present()
        }
    }
}

@MainActor final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    private var model: PrismModel?

    private init() { super.init(window: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    func prepare(model: PrismModel) { self.model = model }

    func show(model: PrismModel) {
        prepare(model: model)
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
        present()
    }

    func present() {
        guard let model else { return }
        if window == nil {
            let content = NSHostingController(rootView: PrismSettings(model: model))
            let preferences = NSWindow(contentViewController: content)
            preferences.title = "IpBan Settings"
            preferences.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            preferences.setContentSize(NSSize(width: 840, height: 600))
            preferences.minSize = NSSize(width: 720, height: 520)
            preferences.center()
            preferences.isReleasedWhenClosed = false
            preferences.hidesOnDeactivate = false
            preferences.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window = preferences
            // AppKit delivers this on the main thread. A block that calls
            // MainActor.assumeIsolated traps on the Xcode 16.4 runtime.
            NotificationCenter.default.addObserver(self, selector: #selector(settingsWindowWillClose(_:)), name: NSWindow.willCloseNotification, object: preferences)
        } else if let hosting = window?.contentViewController as? NSHostingController<PrismSettings> {
            hosting.rootView = PrismSettings(model: model)
        }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    @objc private func settingsWindowWillClose(_ notification: Notification) {
        guard let settings = window, notification.object as AnyObject? === settings else { return }
        let others = NSApplication.shared.windows.contains { candidate in
            candidate !== settings && candidate.isVisible && candidate.canBecomeKey
        }
        if !others { NSApplication.shared.setActivationPolicy(.accessory) }
    }
}
