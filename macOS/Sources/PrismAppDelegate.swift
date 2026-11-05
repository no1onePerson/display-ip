import AppKit
import Foundation
import Darwin

/// Release automation exercises the same settings-window action as the gear.
@MainActor final class PrismAppDelegate: NSObject, NSApplicationDelegate {
    private var smokeModel: PrismModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.contains("--smoke-test-settings") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            let model = PrismModel()
            self.smokeModel = model
            let controller = SettingsWindowController.shared
            controller.show(model: model)
            guard let window = controller.window, window.isVisible else {
                print("Settings window failed to open")
                exit(1)
            }
            window.close()
            controller.show(model: model)
            guard controller.window === window, window.isVisible else {
                print("Settings window failed to reopen")
                exit(1)
            }
            print("IPBAN_SETTINGS_SMOKE_OK")
            NSApplication.shared.terminate(nil)
        }
    }
}
