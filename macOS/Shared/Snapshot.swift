import Foundation

struct Snapshot: Codable {
    var ip: String
    var country: String
    var city: String
    var region: String
    var organization: String
    var timezone: String
    var provider: String
    var date: Date
    var flag: String {
        guard country.count == 2 else { return "◎" }
        return country.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
    }
    static let suite = "group.com.displayip.shared"
    static func load() -> Snapshot? {
        guard let data = UserDefaults(suiteName: suite)?.data(forKey: "snapshot") else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    func save() {
        UserDefaults(suiteName: Self.suite)?.set(try? JSONEncoder().encode(self), forKey: "snapshot")
    }
}
