import SwiftUI
import ServiceManagement
import UserNotifications
import PrismCore

struct PrismSettings: View {
    @ObservedObject var model: PrismModel
    @State private var selection = "General"
    @AppStorage("interval") private var interval = 60
    @AppStorage("menuFormat") private var menuFormat = "Flag + IP"
    @AppStorage("compact") private var compact = true
    @AppStorage("preferIPv6") private var preferIPv6 = false
    @AppStorage("discoverIPv6") private var discoverIPv6 = true
    @AppStorage("customFormat") private var customFormat = "{flag} {ip}"
    @AppStorage("appearance") private var appearance = "System"
    @AppStorage("provider") private var provider = "automatic"
    @AppStorage("priority") private var priority = "ipwho,ipinfo,ipapi,geojs,freeipapi,ipify,icanhazip,cloudflare"
    @AppStorage("timeout") private var timeout = 8.0
    @AppStorage("notify") private var notify = false
    @AppStorage("notifyIP") private var notifyIP = true
    @AppStorage("notifyConnection") private var notifyConnection = false
    @AppStorage("quiet") private var quiet = false
    @AppStorage("quietStart") private var quietStart = 22
    @AppStorage("quietEnd") private var quietEnd = 8
    @AppStorage("sound") private var sound = false
    @AppStorage("soundPreset") private var soundPreset = "Crystal Pulse"
    @AppStorage("volume") private var volume = 0.25
    @AppStorage("retention") private var retention = 30
    @AppStorage("privacy") private var privacy = false
    @State private var loginStatus = SMAppService.mainApp.status
    @State private var permission = "Checking…"
    @State private var error: String?
    @State private var confirmClear = false
    @State private var ipinfoKey = ""
    @State private var keyStatus = ""
    var body: some View {
        HStack(spacing: 0) {
            List { ForEach(["General", "Menu Bar", "Providers", "Notifications", "Sounds", "History", "Privacy", "About"], id: \.self) { section in Button(section) { selection = section }.buttonStyle(.plain).fontWeight(selection == section ? .semibold : .regular).padding(.vertical, 5) } }.frame(width: 155)
            Form {
                switch selection {
                case "Menu Bar": menu
                case "Providers": providers
                case "Notifications": notifications
                case "Sounds": sounds
                case "History": history
                case "Privacy": privacySettings
                case "About": about
                default: general
                }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }.formStyle(.grouped).frame(maxWidth: .infinity)
        }.frame(width: 720, height: 560).task { await refreshPermission() }
            .onChange(of: interval) { _, _ in model.restartSchedule() }
            .onChange(of: privacy) { _, _ in model.persistSnapshot() }
            .onChange(of: retention) { _, _ in model.saveHistory() }
            .confirmationDialog("Delete all cached addresses and history?", isPresented: $confirmClear) { Button("Delete local data", role: .destructive) { model.clearAll() } }
    }
    var general: some View {
        Section("General") {
            Toggle("Launch at login", isOn: Binding(get: { loginStatus == .enabled || loginStatus == .requiresApproval }, set: { enabled in
                do { if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }; loginStatus = SMAppService.mainApp.status } catch { self.error = error.localizedDescription; loginStatus = SMAppService.mainApp.status }
            }))
            if loginStatus == .requiresApproval { Button("Approve in System Settings") { SMAppService.openSystemSettingsLoginItems() } }
            Picker("Appearance", selection: $appearance) { ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) } }
            Picker("Refresh interval", selection: $interval) { Text("Manual only").tag(0); ForEach([30, 60, 120, 300, 600, 900, 1800], id: \.self) { Text($0 < 60 ? "30 seconds" : "\($0 / 60) minutes").tag($0) } }
            Text("Polling remains subject to provider cooldowns and local request budgets. Aggressive intervals can exhaust free limits.").font(.caption).foregroundStyle(.secondary)
            Toggle("Discover IPv6 separately", isOn: $discoverIPv6)
            Text("Uses an IPv6-only endpoint. Unavailable IPv6 is not treated as an address change.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var menu: some View {
        Section("Menu bar") {
            Picker("Display", selection: $menuFormat) { ForEach(["IP only", "Flag + IP", "Country + IP", "Flag only", "Icon", "ISP", "Custom"], id: \.self) { Text($0) } }
            Toggle("Abbreviate long addresses", isOn: $compact); Toggle("Prefer IPv6", isOn: $preferIPv6)
            if menuFormat == "Custom" { TextField("Format", text: $customFormat); Text("Tokens: {ip}, {flag}, {country}. Maximum 48 characters displayed.").font(.caption) }
        }
    }
    var providers: some View {
        Section("Providers") {
            Picker("Selection", selection: $provider) { Text("Automatic fallback").tag("automatic"); ForEach(ProviderID.allCases) { Text($0.name).tag($0.rawValue) } }
            ForEach(ProviderID.allCases) { item in ProviderToggle(provider: item) }
            TextField("Automatic priority", text: $priority)
            Text("Comma-separated provider IDs. Manual mode uses only the selected provider. All providers contacted see your IP.").font(.caption).foregroundStyle(.secondary)
            Slider(value: $timeout, in: 2...30, step: 1) { Text("Timeout: \(Int(timeout)) seconds") }
            SecureField("Optional IPinfo token", text: $ipinfoKey)
            Button("Save token to Keychain") { do { try KeychainStore.set(ipinfoKey, account: "IPinfo"); keyStatus = ipinfoKey.isEmpty ? "Token removed" : "Token saved"; ipinfoKey = "" } catch { self.error = error.localizedDescription } }
            if !keyStatus.isEmpty { Text(keyStatus).font(.caption) }
            Button("Test selection") { Task { await model.refresh() } }.disabled(model.loading)
            Button("Reset statistics") { Task { await model.resetHealth() } }
            Text("Resetting statistics preserves request budgets and cooldowns.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var notifications: some View {
        Section("Notifications") {
            LabeledContent("System permission", value: permission)
            Toggle("Enable notifications", isOn: $notify).onChange(of: notify) { _, enabled in
                if enabled { Task { do { notify = try await model.notifications.request(); await refreshPermission() } catch { self.error = error.localizedDescription; notify = false } } }
            }
            Button("Open notification settings") { if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(url) } }
            Toggle("Confirmed IP changes", isOn: $notifyIP); Toggle("Connection lost / restored", isOn: $notifyConnection)
            Toggle("Quiet hours", isOn: $quiet)
            if quiet { Stepper("Start: \(quietStart):00", value: $quietStart, in: 0...23); Stepper("End: \(quietEnd):00", value: $quietEnd, in: 0...23) }
            Text("Identical event types are limited to one notification per minute. Privacy mode also hides notification details.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var sounds: some View {
        Section("Sounds") {
            Toggle("Play sounds for delivered events", isOn: $sound)
            Picker("Preset", selection: $soundPreset) { ForEach(SoundService.presets, id: \.self) { Text($0) } }
            Slider(value: $volume, in: 0...1) { Text("Volume") }
            Button("Preview sound") { model.sounds.play(preview: true) }
            Text("Original synthesized tones. Quiet hours also silence previews.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var history: some View {
        Section("Local history") {
            Picker("Retention", selection: $retention) { ForEach([1, 7, 30, 90, 365], id: \.self) { Text("\($0) days").tag($0) } }
            Button("Export JSON…") { model.exportHistory(csv: false) }; Button("Export CSV…") { model.exportHistory(csv: true) }
            Button("Clear history", role: .destructive) { model.clearHistory() }
            Text("Exports contain real addresses even when privacy mode is enabled. Choose a private destination.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var privacySettings: some View {
        Section("Privacy") {
            Toggle("Hide sensitive information", isOn: $privacy)
            Text("Hides values in the app and notifications and removes them from the widget cache. Local history is retained until you delete it. No analytics or telemetry is collected.").font(.callout)
            Button("Delete cached data and history…", role: .destructive) { confirmClear = true }
        }
    }
    var about: some View {
        Section("IP Prism") {
            Label("Your connection, in focus.", systemImage: "pyramid.fill").font(.title2)
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3.0")")
            Link("Source, updates, and releases", destination: URL(string: "https://github.com/no1onePerson/display-ip/releases")!)
            Text("MIT License · Native SwiftUI, Network.framework, and WidgetKit. Provider data is approximate and subject to each service’s terms.").foregroundStyle(.secondary)
        }
    }
    func refreshPermission() async {
        switch await model.notifications.permission() { case .authorized: permission = "Allowed"; case .denied: permission = "Denied"; case .notDetermined: permission = "Not requested"; case .provisional: permission = "Provisional"; default: permission = "Unknown" }
        loginStatus = SMAppService.mainApp.status
    }
}
struct ProviderToggle: View {
    let provider: ProviderID
    @AppStorage private var enabled: Bool
    init(provider: ProviderID) { self.provider = provider; _enabled = AppStorage(wrappedValue: true, "provider.\(provider.rawValue)") }
    var body: some View { Toggle(provider.name, isOn: $enabled) }
}
