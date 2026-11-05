import AppKit
import Darwin
import Foundation

/// Release automation exercises the same deferred settings action as the gear.
@MainActor final class PrismAppDelegate: NSObject, NSApplicationDelegate {
    private var smokeModel: PrismModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.contains("--smoke-test-settings") else { return }
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        fputs("IPBAN_SETTINGS_SMOKE_START\n", stdout)
        let model = PrismModel()
        smokeModel = model
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            SettingsOpener.open(model: model)
            guard let window = await self.waitForSettings() else { self.smokeFail("Settings window failed to open") }
            window.close()
            try? await Task.sleep(for: .milliseconds(200))
            SettingsOpener.open(model: model)
            guard let reopened = await self.waitForSettings(), reopened === window else { self.smokeFail("Settings window failed to reopen") }
            fputs("IPBAN_SETTINGS_SMOKE_OK\n", stdout)
            NSApplication.shared.terminate(nil)
        }
    }

    private func waitForSettings() async -> NSWindow? {
        for _ in 0..<24 {
            if let window = SettingsWindowController.shared.window, window.isVisible, window.frame.width >= 700 { return window }
            try? await Task.sleep(for: .milliseconds(150))
        }
        if let window = SettingsWindowController.shared.window {
            fputs("visible=\(window.isVisible) width=\(window.frame.width)\n", stderr)
        } else {
            fputs("settings window missing\n", stderr)
        }
        return nil
    }

    private func smokeFail(_ message: String) -> Never {
        fputs(message + "\n", stderr)
        exit(1)
    }
}
