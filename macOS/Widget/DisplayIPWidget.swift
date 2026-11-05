import SwiftUI
import WidgetKit

struct Entry: TimelineEntry { let date: Date; let snapshot: Snapshot? }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: Date(), snapshot: Snapshot.load())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) { completion(Timeline(entries: [Entry(date: Date(), snapshot: Snapshot.load())], policy: .after(Date().addingTimeInterval(900)))) }
}
struct PrismWidgetView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color {
        colorScheme == .dark ? Color(red: 100.0 / 255, green: 217.0 / 255, blue: 242.0 / 255) : Color(red: 8.0 / 255, green: 105.0 / 255, blue: 132.0 / 255)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("IpBan", systemImage: "network").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                if let data = entry.snapshot { Text(data.online ? "Cached" : "Offline").font(.caption2.weight(.medium)).foregroundStyle(data.online ? Color.secondary : Color.orange) }
            }
            if let data = entry.snapshot {
                if data.privateMode {
                    Label("Privacy mode", systemImage: "hand.raised.fill").font(.headline)
                    Text("Address hidden").font(.caption).foregroundStyle(.secondary)
                } else {
                    switch family {
                    case .systemMedium:
                        HStack(alignment: .top, spacing: 14) {
                            widgetAddress("IPv4", data.ipv4)
                            widgetAddress("IPv6", data.ipv6)
                        }
                        Text([data.city, data.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")).font(.caption).lineLimit(1)
                    case .systemLarge:
                        Text("Connection summary").font(.headline)
                        widgetAddress("IPv4", data.ipv4)
                        widgetAddress("IPv6", data.ipv6)
                        Divider()
                        widgetRow("Location", [data.city, data.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
                        widgetRow("Network", data.organization)
                        widgetRow("Provider", data.provider)
                    default:
                        widgetAddress(data.ipv4 != nil ? "PUBLIC IPv4" : "PUBLIC IPv6", data.ipv4 ?? data.ipv6)
                    }
                }
                Spacer(minLength: 0)
                if data.date == .distantPast { Text("No successful update yet").font(.caption2).foregroundStyle(.secondary) }
                else { Text("Updated \(data.date, style: .relative) ago").font(.caption2).foregroundStyle(.secondary) }
                Text("Updates are scheduled by macOS").font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(2)
            } else {
                Text("Open IpBan").font(.headline)
                Text("Your latest connection will appear here.").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(.regularMaterial, for: .widget).widgetURL(URL(string: "ipban://details"))
    }
    func widgetAddress(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(accent)
            Text(value ?? "Unavailable").font(.system(.callout, design: .monospaced).weight(.semibold)).lineLimit(2).minimumScaleFactor(0.65)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    func widgetRow(_ label: String, _ value: String?) -> some View {
        HStack { Text(label).foregroundStyle(.secondary); Spacer(); Text(value?.isEmpty == false ? value ?? "Unavailable" : "Unavailable").lineLimit(1) }.font(.caption)
    }
}
@main struct IpBanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IpBan", provider: Provider()) { PrismWidgetView(entry: $0) }
            .configurationDisplayName("IpBan").description("Your last successful connection lookup. Updates are scheduled by macOS.").supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
