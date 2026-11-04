import SwiftUI
import AppKit
import PrismCore

struct PrismPanel: View {
    @ObservedObject var model: PrismModel
    @AppStorage("privacy") private var privacy = false
    @AppStorage("onboarded") private var onboarded = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var copied = false
    @State private var search = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "pyramid.fill").font(.title2).foregroundStyle(.cyan, .purple)
                VStack(alignment: .leading) { Text("IP Prism").font(.headline); Text(model.online ? "Your connection, in focus" : "Offline · cached information").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Circle().fill(model.online ? .green : .orange).frame(width: 7, height: 7).accessibilityLabel(model.online ? "Online" : "Offline")
                SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.plain).help("Settings")
            }
            if !onboarded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A clearer view of your network.").font(.title2.bold())
                    Text("IP Prism contacts public IP services to find your internet address. Location is approximate. History stays on this Mac.")
                    Text("Notifications and launch at login are optional in Settings. Add the widget from macOS Edit Widgets.").foregroundStyle(.secondary)
                    Button("Get started") { onboarded = true }.buttonStyle(.borderedProminent)
                }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            } else {
                Picker("Section", selection: $model.selectedTab) { ForEach(["Overview", "Network", "Location", "Providers", "History"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        switch model.selectedTab {
                        case "Network": network
                        case "Location": location
                        case "Providers": providers
                        case "History": history
                        default: overview
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
                }.frame(height: 300).background(reduceTransparency ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.primary.opacity(0.08)))
                if let error = model.error { Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange) }
                HStack {
                    Button { copy(model.current?.address.value) } label: { Label(copied ? "Copied" : "Copy IP", systemImage: copied ? "checkmark" : "doc.on.doc") }.disabled(model.current == nil || privacy)
                    Spacer()
                    if model.loading { ProgressView().controlSize(.small) }
                    Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(model.loading || !model.online).keyboardShortcut("r")
                }
            }
            HStack { Text("Local history. No telemetry.").font(.caption2).foregroundStyle(.secondary); Spacer(); Button("Quit") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).font(.caption) }
        }.padding(22).frame(width: 490).background(.regularMaterial)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.selectedTab)
            .onOpenURL { url in if url.scheme == "ipprism" { openWindow(id: "details"); NSApplication.shared.activate(ignoringOtherApps: true) } }
            .onChange(of: privacy) { _, _ in model.persistSnapshot() }
    }
    var overview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PUBLIC CONNECTION").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
            Text(privacy ? "•••.•••.•••.•••" : model.current?.address.value ?? model.ipv4 ?? model.ipv6 ?? "Finding your connection…").font(.system(size: 28, weight: .medium, design: .rounded)).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            if let data = model.current {
                Text(privacy ? "Location hidden" : [data.flag, data.city, data.countryName ?? data.countryCode].compactMap { $0 }.joined(separator: " ")).foregroundStyle(.secondary)
                Divider(); row("Network", data.isp ?? data.organization); row("Provider", data.providerName)
                HStack { Text("Last success"); Spacer(); Text(data.fetchedAt, style: .relative) }.font(.caption).foregroundStyle(.secondary)
                if Date().timeIntervalSince(data.fetchedAt) > 180 || model.error != nil { Label("Cached · may be stale", systemImage: "clock").font(.caption).foregroundStyle(.orange) }
            } else { Text("Waiting for a successful provider response. Cached addresses may be stale.").foregroundStyle(.secondary) }
        }
    }
    var network: some View {
        VStack(spacing: 12) {
            row("IPv4", model.ipv4); row("IPv6", model.ipv6); row("Interface", model.interface); row("ISP", model.current?.isp); row("Organization", model.current?.organization); row("ASN", model.current?.asn)
            Divider(); row("VPN / proxy", "Unknown — no classification evidence")
            Text("An address or ISP change alone does not prove a VPN is active.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var location: some View {
        VStack(spacing: 12) {
            row("Country", model.current?.countryName ?? model.current?.countryCode); row("Region", model.current?.region); row("City", model.current?.city); row("Postal code", model.current?.postalCode); row("Timezone", model.current?.timezone)
            if let lat = model.current?.latitude, let lon = model.current?.longitude { row("Coordinates", "\(lat), \(lon)") }
            Text("Approximate IP-based location, not your physical position.").font(.caption).foregroundStyle(.secondary)
        }
    }
    var providers: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(ProviderID.allCases) { provider in
                let health = model.health[provider]
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(provider.name).font(.headline); Spacer(); Text(health?.lastSuccess == nil ? "Not verified" : "\(health?.successes ?? 0) successes").font(.caption).foregroundStyle(.secondary) }
                    Text(provider.capabilities.contains(.location) ? "IP discovery · location" : "IP discovery only").font(.caption).foregroundStyle(.secondary)
                    if let health { Text("\(health.failures) failures · \(Int((health.latency ?? 0) * 1000)) ms").font(.caption); if let next = health.nextAllowed, next > Date() { Text("Next request: \(next, style: .relative)").font(.caption).foregroundStyle(.orange) }; if let error = health.lastError { Text(error).font(.caption2).foregroundStyle(.secondary) } }
                }; Divider()
            }
        }
    }
    var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search history", text: $search).textFieldStyle(.roundedBorder)
            Text("\(model.history.count) confirmed changes").font(.caption).foregroundStyle(.secondary)
            if model.history.isEmpty { ContentUnavailableView("No changes yet", systemImage: "clock", description: Text("Changes appear after two consecutive matching observations.")) }
            ForEach(model.history.filter { search.isEmpty || $0.current.address.value.contains(search) || ($0.current.city ?? "").localizedCaseInsensitiveContains(search) }) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Label(privacy ? "Address hidden" : event.current.address.value, systemImage: "arrow.triangle.branch").font(.headline)
                    Text(privacy ? "Previous address hidden" : "From \(event.previous.value)").font(.caption).foregroundStyle(.secondary)
                    Text(event.date, style: .date).font(.caption2)
                    Text(event.reason).font(.caption2).foregroundStyle(.secondary)
                }; Divider()
            }
        }
    }
    func row(_ title: String, _ value: String?) -> some View {
        HStack(alignment: .top) { Text(title).foregroundStyle(.secondary); Spacer(); Text(privacy ? "Hidden" : value ?? "Unavailable").multilineTextAlignment(.trailing).textSelection(.enabled) }.font(.callout)
    }
    func copy(_ value: String?) {
        guard let value else { return }; NSPasteboard.general.clearContents(); NSPasteboard.general.setString(value, forType: .string); copied = true
        Task { try? await Task.sleep(for: .seconds(2)); copied = false }
    }
}
