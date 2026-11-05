import AppKit
import Foundation

/// Release automation exercises the same deferred settings action as the gear.
@MainActor final class PrismAppDelegate: NSObject, NSApplicationDelegate {
    private var smokeModel: PrismModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.contains("--smoke-test-settings") else { return }
        let model = PrismModel()
        smokeModel = model
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            SettingsOpener.open(model: model)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let controller = SettingsWindowController.shared
                guard let window = controller.window, window.isVisible, window.frame.width >= 700 else {
                    print("Settings window failed to open")
                    exit(1)
                }
                window.close()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    SettingsOpener.open(model: model)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        guard controller.window === window, window.isVisible else {
                            print("Settings window failed to reopen")
                            exit(1)
                        }
                        print("IPBAN_SETTINGS_SMOKE_OK")
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
    }
}
