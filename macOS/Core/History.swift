import Foundation

public struct ChangeEvent: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var date: Date
    public var previous: IPAddress
    public var current: Intelligence
    public var reason: String
    public var confirmed: Bool
}
public struct ChangeDetector: Sendable {
    private var accepted: [Family: Intelligence] = [:]
    private var candidates: [Family: IPAddress] = [:]
    public init() {}
    public mutating func observe(_ result: Intelligence) -> ChangeEvent? {
        let family = result.address.family
        guard let old = accepted[family] else { accepted[family] = result; return nil }
        guard old.address != result.address else { candidates[family] = nil; accepted[family] = result; return nil }
        guard candidates[family] == result.address else { candidates[family] = result.address; return nil }
        candidates[family] = nil; accepted[family] = result
        return ChangeEvent(date: result.fetchedAt, previous: old.address, current: result, reason: "Confirmed by two consecutive observations", confirmed: true)
    }
}
public struct NotificationPolicy: Sendable {
    public var enabled = false, privacy = false
    public var quietStart = 22, quietEnd = 8, quietEnabled = false
    public var cooldown: TimeInterval = 60
    private var sent: [String: Date] = [:]
    public init() {}
    public func isQuiet(hour: Int) -> Bool { quietEnabled && (quietStart == quietEnd || (quietStart < quietEnd ? (quietStart..<quietEnd).contains(hour) : hour >= quietStart || hour < quietEnd)) }
    public mutating func permits(key: String, at date: Date, hour: Int) -> Bool {
        guard enabled, !isQuiet(hour: hour), date.timeIntervalSince(sent[key] ?? .distantPast) >= cooldown else { return false }
        sent[key] = date
        return true
    }
}
public struct HistoryStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> [ChangeEvent] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([ChangeEvent].self, from: Data(contentsOf: url))
    }
    public func save(_ events: [ChangeEvent], days: Int = 30, now: Date = Date()) throws {
        let retained = Self.retain(events, days: days, now: now)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(retained).write(to: url, options: .atomic)
    }
    public static func retain(_ events: [ChangeEvent], days: Int, now: Date) -> [ChangeEvent] {
        events.filter { $0.date >= now.addingTimeInterval(-Double(max(1, days)) * 86400) }
    }
    public static func csv(_ events: [ChangeEvent]) -> String {
        func quote(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let formatter = ISO8601DateFormatter()
        return "timestamp,family,old_ip,new_ip,country,city,isp,asn,provider,reason,confirmed\n" + events.map { event in
            [formatter.string(from: event.date), event.previous.family.rawValue, event.previous.value, event.current.address.value, event.current.countryCode ?? "", event.current.city ?? "", event.current.isp ?? "", event.current.asn ?? "", event.current.providerName, event.reason, String(event.confirmed)].map(quote).joined(separator: ",")
        }.joined(separator: "\n")
    }
}
