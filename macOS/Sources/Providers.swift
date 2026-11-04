import Foundation
import Network

struct IPProvider: Identifiable {
    let id: String
    let endpoint: String
    static let all: [Self] = [
        .init(id: "ipwho.is", endpoint: "https://ipwho.is/"),
        .init(id: "IPinfo", endpoint: "https://ipinfo.io/json"),
        .init(id: "ipapi.co", endpoint: "https://ipapi.co/json/"),
        .init(id: "IPWhois.app", endpoint: "https://ipwhois.app/json/"),
        .init(id: "FreeIPAPI", endpoint: "https://free.freeipapi.com/api/json"),
        .init(id: "ipapi.is", endpoint: "https://api.ipapi.is/"),
        .init(id: "GeoJS", endpoint: "https://get.geojs.io/v1/ip/geo.json")
    ]
    func lookup() async throws -> Snapshot {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["success"] as? Bool != false,
              json["error"] == nil || json["error"] as? Bool == false else { throw URLError(.badServerResponse) }
        func value(_ keys: String...) -> String {
            for key in keys {
                var item: Any = json
                for part in key.split(separator: ".") { item = (item as? [String: Any])?[String(part)] ?? "" }
                if let text = item as? String, !text.isEmpty { return text }
            }
            return ""
        }
        let ip = value("ip", "ipAddress")
        guard IPv4Address(ip) != nil || IPv6Address(ip) != nil else { throw URLError(.cannotParseResponse) }
        return Snapshot(ip: ip, country: value("country_code", "countryCode", "location.country_code", "country"), city: value("city", "cityName", "location.city"), region: value("region", "regionName", "location.state"), organization: value("connection.isp", "org", "isp", "organization", "asn.org", "company.name"), timezone: value("timezone.id", "timezone", "location.timezone", "timeZone"), provider: id, date: Date())
    }
}
