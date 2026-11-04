import SwiftUI
import WidgetKit

struct Entry: TimelineEntry { let date: Date; let snapshot: Snapshot? }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: Date(), snapshot: Snapshot.load())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: Date(), snapshot: Snapshot.load())], policy: .after(Date().addingTimeInterval(900))))
    }
}
@main struct DisplayIPWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DisplayIP", provider: Provider()) { entry in
            VStack(alignment: .leading, spacing: 12) {
                Label("Display IP", systemImage: "network").font(.caption).foregroundStyle(.secondary)
                Text(entry.snapshot?.ip ?? "Open Display IP").font(.system(.title3, design: .rounded).weight(.semibold)).minimumScaleFactor(0.5)
                if let info = entry.snapshot {
                    Text("\(info.flag) \(info.city)").font(.caption)
                    Text("Updated \(info.date, style: .relative) ago").font(.caption2).foregroundStyle(.secondary)
                } else { Text("Your connection at a glance.").font(.caption) }
            }.frame(maxWidth: .infinity, alignment: .leading).containerBackground(.quaternary, for: .widget)
        }.configurationDisplayName("Your public IP").description("The last connection refreshed by Display IP. Keep the app running for updates.").supportedFamilies([.systemSmall, .systemMedium])
    }
}
