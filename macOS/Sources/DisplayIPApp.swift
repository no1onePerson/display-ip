import SwiftUI
import AppKit
import Network
import ServiceManagement
import UserNotifications
import WidgetKit

@MainActor final class IPModel: ObservableObject {
    @Published var snapshot = Snapshot.load()
    @Published var loading = false
    @Published var error: String?
    @Published var failures: [String] = []
    private let monitor = NWPathMonitor()
    private var timer: Timer?
    init() {
        UserDefaults.standard.register(defaults: ["interval": 300, "sound": true])
        monitor.pathUpdateHandler = { [weak self] _ in Task { @MainActor in await self?.refresh() } }
        monitor.start(queue: DispatchQueue(label: "DisplayIP.network"))
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let interval = UserDefaults.standard.integer(forKey: "interval")
                if interval > 0 && Date().timeIntervalSince(self.snapshot?.date ?? .distantPast) >= Double(interval) { await self.refresh() }
            }
        }
    }
    func refresh() async {
        guard !loading else { return }
        loading = true; error = nil; failures = []
        defer { loading = false }
        let preferred = UserDefaults.standard.string(forKey: "provider") ?? "Automatic"
        let providers = IPProvider.all.sorted { ($0.id == preferred ? 0 : 1) < ($1.id == preferred ? 0 : 1) }
        for provider in providers {
            do {
                let result = try await provider.lookup()
                if let old = snapshot, old.ip != result.ip, UserDefaults.standard.bool(forKey: "notify") {
                    let content = UNMutableNotificationContent()
                    content.title = "Public IP changed"
                    content.body = "\(old.ip) → \(result.ip)"
                    if UserDefaults.standard.bool(forKey: "sound") { content.sound = .default }
                    try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
                }
                snapshot = result; result.save()
                WidgetCenter.shared.reloadAllTimelines()
                return
            } catch { failures.append("\(provider.id): \(error.localizedDescription)") }
        }
        error = "Couldn’t refresh. Showing the last successful result."
    }
    func label(format: String, country: String) -> String {
        guard let snapshot else { return "Display IP" }
        let parts = snapshot.ip.split(separator: ".")
        var ip = snapshot.ip
        if format == "Hidden" { ip = "" }
        else if parts.count == 4 {
            if format == "First two" { ip = "\(parts[0]).\(parts[1]).…" }
            if format == "Last two" { ip = "….\(parts[2]).\(parts[3])" }
            if format == "First and last" { ip = "\(parts[0]).… .\(parts[3])" }
        } else if format != "Full" { ip = String(ip.prefix(9)) + "…" }
        let prefix = country == "Flag" ? snapshot.flag : country == "Code" ? snapshot.country : ""
        return [prefix, ip].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

@main struct DisplayIPApp: App {
    @StateObject private var model = IPModel()
    @AppStorage("format") private var format = "Full"
    @AppStorage("country") private var country = "Flag"
    var body: some Scene {
        MenuBarExtra {
            Dashboard(model: model)
        } label: {
            let label = model.label(format: format, country: country)
            if label.isEmpty { Image(systemName: "network") } else { Text(label).monospacedDigit() }
        }.menuBarExtraStyle(.window)
        Settings { Preferences(model: model) }
    }
}

struct Dashboard: View {
    @ObservedObject var model: IPModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "globe.americas.fill").foregroundStyle(.cyan)
                Text("Display IP").font(.headline)
                Spacer()
                if model.loading { ProgressView().controlSize(.small) }
                SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR PUBLIC CONNECTION").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                Text(model.snapshot?.ip ?? "Finding your IP…").font(.system(size: 29, weight: .medium, design: .rounded)).textSelection(.enabled).contentTransition(.numericText())
                if let info = model.snapshot {
                    Text("\(info.flag)  \([info.city, info.region].filter { !$0.isEmpty }.joined(separator: ", "))").foregroundStyle(.secondary)
                    Divider()
                    detail("Network", info.organization)
                    detail("Time zone", info.timezone)
                    detail("Provider", info.provider)
                    HStack { Text("Updated"); Spacer(); Text(info.date, style: .relative) }.font(.caption).foregroundStyle(.secondary)
                }
            }.padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.18)))
            if let error = model.error { Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange) }
            if !model.failures.isEmpty {
                DisclosureGroup("Provider diagnostics") { ForEach(model.failures, id: \.self) { Text($0).font(.caption2).textSelection(.enabled) } }
            }
            HStack {
                Button { if let ip = model.snapshot?.ip { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(ip, forType: .string) } } label: { Label("Copy IP", systemImage: "doc.on.doc") }.disabled(model.snapshot == nil)
                Spacer()
                Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(model.loading).keyboardShortcut("r")
            }
            HStack { Text("Private by design. No analytics.").font(.caption2).foregroundStyle(.secondary); Spacer(); Button("Quit") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).font(.caption) }
        }.padding(22).frame(width: 390).background(.regularMaterial).animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.snapshot?.ip)
    }
    func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) { Text(label).foregroundStyle(.secondary); Spacer(); Text(value.isEmpty ? "Unavailable" : value).multilineTextAlignment(.trailing) }.font(.callout)
    }
}

struct Preferences: View {
    @ObservedObject var model: IPModel
    @AppStorage("format") private var format = "Full"
    @AppStorage("country") private var country = "Flag"
    @AppStorage("interval") private var interval = 300
    @AppStorage("provider") private var provider = "Automatic"
    @AppStorage("notify") private var notify = false
    @AppStorage("sound") private var sound = true
    @State private var login = SMAppService.mainApp.status == .enabled
    @State private var error = ""
    var body: some View {
        Form {
            Section("Menu bar") {
                Picker("IP format", selection: $format) { ForEach(["Full", "First two", "Last two", "First and last", "Hidden"], id: \.self) { Text($0) } }
                Picker("Country", selection: $country) { ForEach(["Flag", "Code", "Hidden"], id: \.self) { Text($0) } }
            }
            Section("Connection") {
                Picker("Preferred provider", selection: $provider) { Text("Automatic").tag("Automatic"); ForEach(IPProvider.all) { Text($0.id).tag($0.id) } }
                Picker("Refresh interval", selection: $interval) { Text("Off").tag(0); Text("1 minute").tag(60); Text("5 minutes").tag(300); Text("15 minutes").tag(900) }
                Text("Refreshes on network changes. If a provider fails, the next provider is tried. Each contacted provider sees your public IP; its privacy policy and usage limits apply.").font(.caption).foregroundStyle(.secondary)
            }
            Section("System") {
                Toggle("Start at login", isOn: $login).onChange(of: login) { _, enabled in
                    do { if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
                    catch { self.error = error.localizedDescription; login = SMAppService.mainApp.status == .enabled }
                }
                Toggle("Notify when IP changes", isOn: $notify).onChange(of: notify) { _, enabled in
                    if enabled { Task { do { notify = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) } catch { self.error = error.localizedDescription; notify = false } } }
                }
                Toggle("Play notification sound", isOn: $sound).disabled(!notify)
                if !error.isEmpty { Text(error).foregroundStyle(.red).font(.caption) }
            }
        }.formStyle(.grouped).padding().frame(width: 510, height: 550)
    }
}
