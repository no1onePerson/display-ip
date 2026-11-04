import Foundation

struct Snapshot: Codable {
    var ipv4: String?
    var ipv6: String?
    var country: String?
    var city: String?
    var organization: String?
    var provider: String?
    var date: Date
    var online: Bool
    var privateMode: Bool
    static let suite = "group.com.displayip.shared"
    static func load() -> Snapshot? {
        guard let data = UserDefaults(suiteName: suite)?.data(forKey: "snapshot") else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    func save() { UserDefaults(suiteName: Self.suite)?.set(try? JSONEncoder().encode(self), forKey: "snapshot") }
    static func clear() { UserDefaults(suiteName: suite)?.removeObject(forKey: "snapshot") }
}
