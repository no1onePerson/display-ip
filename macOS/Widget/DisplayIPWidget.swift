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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("IP Prism", systemImage: "pyramid.fill").font(.caption).foregroundStyle(.secondary)
            if let data = entry.snapshot {
                Text(data.privateMode ? "Privacy mode" : data.ipv4 ?? data.ipv6 ?? "No cached address").font(.system(.title3, design: .rounded).weight(.semibold)).minimumScaleFactor(0.5)
                if family != .systemSmall, !data.privateMode {
                    Text([data.city, data.country].compactMap { $0 }.joined(separator: ", ")).font(.caption)
                    Text(data.organization ?? "Network unavailable").font(.caption)
                }
                if family == .systemLarge, !data.privateMode {
                    Divider(); Text("IPv4: \(data.ipv4 ?? "Unavailable")"); Text("IPv6: \(data.ipv6 ?? "Unavailable")"); Text("Provider: \(data.provider ?? "Unknown")")
                }
                Text(data.online ? "Last known connection" : "Offline · cached").font(.caption2)
                Text("Updated \(data.date, style: .relative) ago").font(.caption2).foregroundStyle(.secondary)
            } else { Text("Open IP Prism").font(.headline); Text("Keep the app running to update this widget.").font(.caption) }
        }.frame(maxWidth: .infinity, alignment: .leading).containerBackground(.quaternary, for: .widget).widgetURL(URL(string: "ipprism://details"))
    }
}
@main struct IPPrismWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IPPrism", provider: Provider()) { PrismWidgetView(entry: $0) }
            .configurationDisplayName("IP Prism").description("Your last successful connection lookup. Updates are scheduled by macOS.").supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
