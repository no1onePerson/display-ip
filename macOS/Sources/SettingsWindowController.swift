import AppKit
import SwiftUI

/// The menu-bar popover can disappear as it opens another scene. Keep the
/// preferences window under AppKit ownership for the lifetime of the app.
@MainActor final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController(existingWindow: nil)

    private init(existingWindow: NSWindow?) { super.init(window: existingWindow) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    func show(model: PrismModel) {
        if window == nil {
            let content = NSHostingController(rootView: PrismSettings(model: model))
            let preferences = NSWindow(contentViewController: content)
            preferences.title = "IpBan Settings"
            preferences.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            preferences.setContentSize(NSSize(width: 720, height: 560))
            preferences.center()
            preferences.isReleasedWhenClosed = false
            window = preferences
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
