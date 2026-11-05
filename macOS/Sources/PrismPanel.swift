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
    @State private var copyNotice = ""
    @State private var appeared = false
    @State private var search = ""
    @State private var onboardingStep = 0
    @AppStorage("appearance") private var appearance = "System"
    private let sections = ["Overview", "Network", "Location", "Providers", "History", "Designer"]
    private var statusLabel: String {
        if !model.online { return "Offline" }
        if model.loading { return "Checking…" }
        if model.current == nil { return "Waiting" }
        if model.error != nil || (model.current.map { Date().timeIntervalSince($0.fetchedAt) > 180 } ?? false) { return "Cached" }
        return "Connected"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "network.badge.shield.half.filled").font(.title2).foregroundStyle(PrismTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("IpBan").font(.system(size: 18, weight: .semibold))
                    Text("Your connection, in focus").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    Circle().fill(model.online ? Color.green : Color.orange).frame(width: 7, height: 7)
                    Text(statusLabel).font(.caption.weight(.medium))
                }.padding(.horizontal, 9).padding(.vertical, 6).background(.thinMaterial, in: Capsule())
                Button { SettingsOpener.open(model: model) } label: {
                    Image(systemName: "gearshape").frame(width: 32, height: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9))
                .help("Settings")
                .accessibilityLabel("Open settings")
                .keyboardShortcut(",", modifiers: .command)
            }
            if !onboarded {
                onboarding
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(sections, id: \.self) { section in
                            Button { model.selectedTab = section } label: {
                                Text(section).font(.system(size: 11, weight: model.selectedTab == section ? .semibold : .regular)).padding(.horizontal, 9).padding(.vertical, 7)
                                    .background(model.selectedTab == section ? Color.primary.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain).accessibilityLabel("\(section) tab").accessibilityAddTraits(model.selectedTab == section ? .isSelected : [])
                        }
                    }.padding(3)
                }.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 11))
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        switch model.selectedTab {
                        case "Network": network
                        case "Location": location
                        case "Providers": providers
                        case "History": history
                        case "Designer": designer
                        default: overview
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 3)
                }.frame(height: 400)
                if let error = model.error { Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true) }
                HStack(spacing: 8) {
                    Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }.disabled(model.loading || !model.online).keyboardShortcut("r")
                    if model.loading { ProgressView().controlSize(.small) }
                    Spacer()
                    Button { copy(model.current?.address.value, announcement: "Copied IP") } label: { Label(copyNotice.isEmpty ? "Copy IP" : copyNotice, systemImage: copied ? "checkmark" : "doc.on.doc") }.buttonStyle(.borderedProminent).tint(PrismTheme.accent).disabled(model.current == nil || privacy)
                    Button("Quit") { NSApplication.shared.terminate(nil) }.help("Quit IpBan")
                }.controlSize(.regular)
            }
        }.padding(16).frame(width: 396).background {
            ZStack {
                if reduceTransparency { Color(nsColor: .windowBackgroundColor) } else { Rectangle().fill(.regularMaterial) }
                LinearGradient(colors: [PrismTheme.accent.opacity(0.06), .clear, Color.purple.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }.opacity(appeared || reduceMotion ? 1 : 0.85).scaleEffect(appeared || reduceMotion ? 1 : 0.98)
            .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { appeared = true } }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.selectedTab)
            .onOpenURL { url in if url.scheme == "ipban" || url.scheme == "ipprism" { openWindow(id: "details"); NSApplication.shared.setActivationPolicy(.regular); NSApplication.shared.activate(ignoringOtherApps: true) } }
            .onChange(of: privacy) { _, _ in model.persistSnapshot() }
    }
    var onboarding: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 5) {
                ForEach(0..<3) { step in Capsule().fill(step == onboardingStep ? PrismTheme.accent : Color.primary.opacity(0.14)).frame(height: 3) }
                Spacer()
                Text("\(onboardingStep + 1) / 3").font(.caption2).foregroundStyle(.secondary)
            }
            Image(systemName: ["network", "paintpalette", "hand.raised"][onboardingStep]).font(.system(size: 25)).foregroundStyle(PrismTheme.accent).padding(12).background(PrismTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            Text(["A clearer view of your network.", "Make it yours.", "Your privacy, explained."][onboardingStep]).font(.title2.weight(.semibold))
            Text(["See your public IPv4 and IPv6, connection details, and recent changes from the menu bar.", "Choose an appearance. You can adjust menu bar format and refresh intervals in Settings.", "The selected IP providers receive your public IP. History stays on this Mac; location is approximate. Notifications and login startup are optional."][onboardingStep]).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if onboardingStep == 1 { Picker("Appearance", selection: $appearance) { ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) } }.pickerStyle(.segmented) }
            if onboardingStep == 2 { Toggle("Hide sensitive values", isOn: $privacy).onChange(of: privacy) { _, _ in model.persistSnapshot() } }
            Spacer(minLength: 15)
            HStack {
                Button("Not now") { onboarded = true }.buttonStyle(.plain).foregroundStyle(.secondary)
                Spacer()
                if onboardingStep > 0 { Button("Back") { onboardingStep -= 1 } }
                Button(onboardingStep == 2 ? "Finish" : "Continue") { if onboardingStep == 2 { onboarded = true } else { onboardingStep += 1 } }.buttonStyle(.borderedProminent).tint(PrismTheme.accent)
            }
        }.padding(16).frame(maxWidth: .infinity, minHeight: 310, alignment: .leading).prismCard()
    }
    var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            addressDetail("IPv4", model.ipv4)
            addressDetail("IPv6", model.ipv6)
            if let data = model.current {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "location.fill").foregroundStyle(PrismTheme.accent).padding(8).background(PrismTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 4) {
                        let location = [data.flag, data.city, data.region, data.countryName ?? data.countryCode].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                        Text(privacy ? "Location hidden" : location.isEmpty ? "Location unavailable" : location).font(.callout.weight(.semibold))
                        Text("Approximate · IP-based location").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.padding(12).prismCard()
                VStack(spacing: 10) {
                    row("Network", data.isp ?? data.organization)
                    Divider()
                    row("Provider", data.providerName)
                    Divider()
                    HStack { Text("Last successful check").foregroundStyle(.secondary); Spacer(); Text(data.fetchedAt, style: .relative) }.font(.caption)
                }.padding(12).prismCard()
                if Date().timeIntervalSince(data.fetchedAt) > 180 || model.error != nil { Label("Cached · may be stale", systemImage: "clock").font(.caption).foregroundStyle(.orange) }
            } else { Text("Waiting for a successful provider response. Cached addresses may be stale.").font(.caption).foregroundStyle(.secondary) }
        }
    }
    func addressDetail(_ label: String, _ address: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label == "IPv4" ? "4" : "6").font(.caption.bold()).foregroundStyle(label == "IPv4" ? PrismTheme.accent : Color.purple).frame(width: 21, height: 21).background((label == "IPv4" ? PrismTheme.accent : Color.purple).opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                Text("Public \(label)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(address == nil ? "Unavailable" : "Last observed").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(alignment: .center, spacing: 10) {
                Text(privacy ? "Hidden" : address ?? "Unavailable").font(.system(size: label == "IPv4" ? 21 : 15, weight: .semibold, design: .monospaced)).textSelection(.enabled).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                if address != nil && !privacy {
                    Button { copy(address, announcement: "Copied \(label)") } label: { Image(systemName: copied && copyNotice == "Copied \(label)" ? "checkmark" : "doc.on.doc").frame(width: 28, height: 28) }.buttonStyle(.plain).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8)).help("Copy \(label) address").accessibilityLabel("Copy \(label) address")
                }
            }
        }.padding(14).prismCard()
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
                    if let health { Text(health.latency.map { "\(health.failures) failures · \(Int($0 * 1000)) ms" } ?? "\(health.failures) failures · latency unavailable").font(.caption); if let next = health.nextAllowed, next > Date() { Text("Next request: \(next, style: .relative)").font(.caption).foregroundStyle(.orange) }; if let error = health.lastError { Text(error).font(.caption2).foregroundStyle(.secondary) } }
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
                    Label(privacy ? "Address hidden" : "\(event.previous.family == .v4 ? "IPv4" : "IPv6") \(event.current.address.value)", systemImage: "arrow.triangle.branch").font(.headline)
                    Text(privacy ? "Previous address hidden" : "\(event.previous.value) → \(event.current.address.value)").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary).textSelection(.enabled)
                    Text(event.date, style: .date).font(.caption2)
                    Text(event.reason).font(.caption2).foregroundStyle(.secondary)
                }; Divider()
            }
        }
    }
    var designer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Design specification").font(.headline)
            Text("Contains no personal IP addresses, location details, or credentials.").font(.caption).foregroundStyle(.secondary)
            Text(DesignerHandoff.text).font(.callout).textSelection(.enabled)
            Button { copy(DesignerHandoff.text, announcement: "Copied specification") } label: { Label(copyNotice == "Copied specification" ? "Copied specification" : "Copy specification", systemImage: copyNotice == "Copied specification" ? "checkmark" : "doc.on.doc") }
        }
    }
    func row(_ title: String, _ value: String?) -> some View {
        HStack(alignment: .top) { Text(title).foregroundStyle(.secondary); Spacer(); Text(privacy ? "Hidden" : value ?? "Unavailable").multilineTextAlignment(.trailing).textSelection(.enabled) }.font(.callout).contextMenu { Button("Copy value") { copy(value, announcement: "Copied \(title)") }.disabled(value == nil || privacy) }
    }
    func copy(_ value: String?, announcement: String) {
        guard let value else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copied = true
        copyNotice = announcement
        AccessibilityNotification.Announcement(announcement).post()
        Task { try? await Task.sleep(for: .seconds(2)); copied = false; copyNotice = "" }
    }
}
