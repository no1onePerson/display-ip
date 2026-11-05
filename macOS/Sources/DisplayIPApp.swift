import SwiftUI
import PrismCore

@main struct IPPrismApp: App {
    @NSApplicationDelegateAdaptor(PrismAppDelegate.self) private var appDelegate
    @StateObject private var model = PrismModel()
    @AppStorage("menuFormat") private var format = "Flag + IP"
    @AppStorage("privacy") private var privacy = false
    @AppStorage("compact") private var compact = true
    @AppStorage("preferIPv6") private var preferIPv6 = false
    @AppStorage("appearance") private var appearance = "System"
    var label: String {
        if privacy { return "IpBan" }
        let ip = (preferIPv6 ? model.ipv6 ?? model.ipv4 : model.ipv4 ?? model.ipv6) ?? "IpBan"
        let short = compact && ip.count > 18 ? String(ip.prefix(8)) + "…" + String(ip.suffix(4)) : ip
        switch format {
        case "IP only": return short
        case "Country + IP": return [model.current?.countryCode, short].compactMap { $0 }.joined(separator: " ")
        case "Flag only": return model.current?.flag.isEmpty == false ? model.current?.flag ?? "IP" : "IP"
        case "ISP": return String((model.current?.isp ?? model.current?.organization ?? "IpBan").prefix(12))
        case "Custom": return (UserDefaults.standard.string(forKey: "customFormat") ?? "{flag} {ip}").replacingOccurrences(of: "{ip}", with: short).replacingOccurrences(of: "{flag}", with: model.current?.flag ?? "").replacingOccurrences(of: "{country}", with: model.current?.countryCode ?? "")
        default: return [model.current?.flag ?? "", short].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
    var body: some Scene {
        MenuBarExtra {
            PrismPanel(model: model).preferredColorScheme(appearance == "Dark" ? .dark : appearance == "Light" ? .light : nil)
        } label: {
            if format == "Icon" { Image(systemName: "network").symbolRenderingMode(.monochrome) }
            else { Text(String(label.prefix(48))).monospacedDigit() }
        }.menuBarExtraStyle(.window)
        Window("IpBan", id: "details") { PrismPanel(model: model) }
        Settings { PrismSettings(model: model) }
    }
}
