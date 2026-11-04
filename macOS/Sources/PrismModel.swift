import SwiftUI
import AppKit
import Network
import WidgetKit
import PrismCore

@MainActor final class PrismModel: ObservableObject {
    @Published var current: Intelligence?
    @Published var ipv4: String?
    @Published var ipv6: String?
    @Published var loading = false
    @Published var online = true
    @Published var interface = "Unknown"
    @Published var error: String?
    @Published var history: [ChangeEvent] = []
    @Published var health: [ProviderID: ProviderHealth] = [:]
    @Published var selectedTab = "Overview"
    private let manager: ProviderManager
    private let ipv6Manager: ProviderManager
    private let cacheURL: URL
    private let monitor = NWPathMonitor()
    private let historyStore: HistoryStore
    private var detector = ChangeDetector()
    private var schedule: Task<Void, Never>?, debounce: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?, sleepObserver: NSObjectProtocol?
    let notifications = NotificationService()
    let sounds = SoundService()
    init() {
        UserDefaults.standard.register(defaults: ["interval": 60, "volume": 0.25, "quietStart": 22, "quietEnd": 8, "retention": 30, "notifyIP": true, "notifyConnection": false])
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("IPPrism")
        manager = ProviderManager(transport: CredentialTransport(), stateURL: root.appendingPathComponent("provider-health.json"))
        ipv6Manager = ProviderManager(stateURL: root.appendingPathComponent("ipv6-health.json"))
        historyStore = HistoryStore(url: root.appendingPathComponent("history.json"))
        cacheURL = root.appendingPathComponent("current.json")
        if let data = try? Data(contentsOf: cacheURL), let cached = try? JSONDecoder().decode(Intelligence.self, from: data) { current = cached; _ = detector.observe(cached) }
        do { history = HistoryStore.retain(try historyStore.load(), days: UserDefaults.standard.integer(forKey: "retention"), now: Date()) } catch { self.error = "History could not be read: \(error.localizedDescription)" }
        if let cached = Snapshot.load() { ipv4 = cached.ipv4; ipv6 = cached.ipv6 }
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let type = path.usesInterfaceType(.wifi) ? "Wi-Fi" : path.usesInterfaceType(.wiredEthernet) ? "Ethernet" : path.usesInterfaceType(.cellular) ? "Cellular" : "Other"
            Task { @MainActor in self?.networkChanged(connected, interface: type) }
        }
        monitor.start(queue: DispatchQueue(label: "IPPrism.network"))
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.restartSchedule() } }
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.schedule?.cancel(); await self?.manager.cancel(); await self?.ipv6Manager.cancel() } }
        notifications.onOpen = { if let url = URL(string: "ipprism://details") { NSWorkspace.shared.open(url) } }
        restartSchedule()
    }
    func networkChanged(_ connected: Bool, interface: String) {
        let changed = online != connected
        online = connected; self.interface = interface
        debounce?.cancel()
        if !connected { Task { await manager.cancel(); await ipv6Manager.cancel() }; error = "Offline · showing cached information" }
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self else { return }
            if changed, UserDefaults.standard.bool(forKey: "notifyConnection") {
                if await self.notifications.send(key: connected ? "connected" : "offline", title: connected ? "Connection restored" : "Connection lost", detail: "IP Prism is \(connected ? "online" : "offline").") { self.sounds.play() }
            }
            if connected { await self.refresh() }
        }
    }
    func restartSchedule() {
        schedule?.cancel()
        schedule = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                let interval = UserDefaults.standard.integer(forKey: "interval")
                if interval == 0 { return }
                do { try await Task.sleep(for: .seconds(max(30, interval))) } catch { return }
            }
        }
    }
    func refresh() async {
        guard !loading, online else { return }
        loading = true
        defer { loading = false }
        let d = UserDefaults.standard
        let enabled = ProviderID.allCases.filter { d.object(forKey: "provider.\($0.rawValue)") == nil || d.bool(forKey: "provider.\($0.rawValue)") }
        let preferred = d.string(forKey: "provider") ?? "automatic"
        let order = (d.string(forKey: "priority") ?? "ipwho,ipinfo,ipapi,geojs,freeipapi,ipify,icanhazip,cloudflare").split(separator: ",").compactMap { ProviderID(rawValue: String($0.trimmingCharacters(in: .whitespaces))) }
        var priority: [ProviderID] = []
        for id in order + enabled where !priority.contains(id) { priority.append(id) }
        priority = priority.filter { enabled.contains($0) }
        if preferred != "automatic", let chosen = ProviderID(rawValue: preferred) { priority = enabled.contains(chosen) ? [chosen] : [] }
        do {
            let result = try await manager.lookup(priority: priority, timeout: d.double(forKey: "timeout") == 0 ? 8 : d.double(forKey: "timeout"), force: true)
            await accept(result)
            current = result; error = nil
            do { try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true); try JSONEncoder().encode(result).write(to: cacheURL, options: .atomic) } catch { self.error = "Could not cache the latest result." }
            if d.bool(forKey: "discoverIPv6") {
                // Explicitly opt-in: an IPv6-only request may be unreachable on this network.
                if let v6 = try? await ipv6Manager.lookup(priority: [.ipify, .icanhazip], force: true, family: .v6) { await accept(v6) }
            }
            persistSnapshot()
        } catch is CancellationError { } catch { self.error = "Refresh unavailable · last successful data retained. See Providers for cooldowns." }
        health = await manager.diagnostics()
    }
    private func accept(_ result: Intelligence) async {
        if result.address.family == .v4 { ipv4 = result.address.value } else { ipv6 = result.address.value }
        if let event = detector.observe(result) {
            history.insert(event, at: 0); saveHistory()
            if UserDefaults.standard.bool(forKey: "notifyIP"), await notifications.send(key: "ip-\(result.address.family.rawValue)", title: "Public \(result.address.family == .v4 ? "IPv4" : "IPv6") changed", detail: "\(event.previous.value) → \(result.address.value)\n\(result.city ?? "") · \(result.providerName)") { sounds.play() }
        }
    }
    func persistSnapshot() {
        let privacy = UserDefaults.standard.bool(forKey: "privacy")
        Snapshot(ipv4: privacy ? nil : ipv4, ipv6: privacy ? nil : ipv6, country: privacy ? nil : current?.countryCode, city: privacy ? nil : current?.city, organization: privacy ? nil : current?.organization, provider: current?.providerName, date: current?.fetchedAt ?? .distantPast, online: online, privateMode: privacy).save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    func saveHistory() {
        let days = UserDefaults.standard.integer(forKey: "retention")
        history = HistoryStore.retain(history, days: days, now: Date())
        do { try historyStore.save(history, days: days) } catch { self.error = "History could not be saved: \(error.localizedDescription)" }
    }
    func clearHistory() { history = []; saveHistory() }
    func clearAll() { try? FileManager.default.removeItem(at: cacheURL); clearHistory(); current = nil; ipv4 = nil; ipv6 = nil; detector = ChangeDetector(); Snapshot.clear(); WidgetCenter.shared.reloadAllTimelines() }
    func resetHealth() async { await manager.resetStatistics(); health = await manager.diagnostics() }
    func exportHistory(csv: Bool) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = csv ? "IPPrism-history.csv" : "IPPrism-history.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { let data = csv ? Data(HistoryStore.csv(history).utf8) : try JSONEncoder().encode(history); try data.write(to: url, options: .atomic) } catch { self.error = error.localizedDescription }
    }
}
