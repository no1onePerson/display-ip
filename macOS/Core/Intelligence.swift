import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public enum Family: String, Codable, Sendable { case v4, v6 }
public struct IPAddress: Codable, Equatable, Hashable, Sendable {
    public let value: String
    public let family: Family
    public init?(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var v4 = in_addr(), v6 = in6_addr()
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        if inet_pton(AF_INET, text, &v4) == 1 {
            guard inet_ntop(AF_INET, &v4, &buffer, socklen_t(buffer.count)) != nil else { return nil }
            family = .v4
        } else if inet_pton(AF_INET6, text, &v6) == 1 {
            guard inet_ntop(AF_INET6, &v6, &buffer, socklen_t(buffer.count)) != nil else { return nil }
            family = .v6
        } else { return nil }
        value = String(decoding: buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
public struct Intelligence: Codable, Equatable, Sendable {
    public var address: IPAddress
    public var countryName: String?, countryCode: String?, region: String?, city: String?, postalCode: String?
    public var latitude: Double?, longitude: Double?
    public var timezone: String?, utcOffset: String?, isp: String?, organization: String?, asn: String?, asnOrganization: String?
    public var providerName: String
    public var fetchedAt: Date
    public init(address: IPAddress, providerName: String, fetchedAt: Date = Date()) {
        self.address = address; self.providerName = providerName; self.fetchedAt = fetchedAt
    }
    public var flag: String {
        guard let code = countryCode?.uppercased(), code.count == 2,
              code.unicodeScalars.allSatisfy({ (65...90).contains($0.value) }) else { return "" }
        return code.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
    }
}
public struct Capabilities: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let discovery = Self(rawValue: 1)
    public static let location = Self(rawValue: 2)
    public static let network = Self(rawValue: 4)
}
public enum ProviderID: String, CaseIterable, Codable, Sendable, Identifiable {
    case ipwho, ipinfo, ipapi, geojs, freeipapi, ipify, icanhazip, cloudflare
    public var id: String { rawValue }
    public var name: String {
        switch self { case .ipwho: "IPWho.is"; case .ipinfo: "IPinfo"; case .ipapi: "ipapi.co"; case .geojs: "GeoJS"; case .freeipapi: "FreeIPAPI"; case .ipify: "ipify"; case .icanhazip: "icanhazip"; case .cloudflare: "Cloudflare Trace" }
    }
    public var endpoint: String {
        switch self {
        case .ipwho: "https://ipwho.is/"
        case .ipinfo: "https://ipinfo.io/json"
        case .ipapi: "https://ipapi.co/json/"
        case .geojs: "https://get.geojs.io/v1/ip/geo.json"
        case .freeipapi: "https://free.freeipapi.com/api/json"
        case .ipify: "https://api.ipify.org?format=json"
        case .icanhazip: "https://icanhazip.com/"
        case .cloudflare: "https://www.cloudflare.com/cdn-cgi/trace"
        }
    }
    public var capabilities: Capabilities {
        switch self { case .ipify, .icanhazip: [.discovery]; case .cloudflare, .freeipapi: [.discovery, .location]; default: [.discovery, .location, .network] }
    }
    public var minimumInterval: TimeInterval { self == .ipapi ? 120 : 60 }
}
public protocol IPProvider: Sendable {
    var id: ProviderID { get }
    func parse(_ data: Data, at: Date) throws -> Intelligence
}
public enum LookupError: Error, Equatable, Sendable { case malformed, invalidIP, http(Int), unavailable, offline }
public struct ProviderAdapter: IPProvider {
    public let id: ProviderID
    public init(_ id: ProviderID) { self.id = id }
    public func parse(_ data: Data, at date: Date = Date()) throws -> Intelligence {
        if id == .icanhazip {
            guard let text = String(data: data, encoding: .utf8), let address = IPAddress(text) else { throw LookupError.invalidIP }
            return Intelligence(address: address, providerName: id.name, fetchedAt: date)
        }
        if id == .cloudflare {
            guard let text = String(data: data, encoding: .utf8) else { throw LookupError.malformed }
            var values: [String: String] = [:]
            for line in text.split(separator: "\n") {
                let pair = line.split(separator: "=", maxSplits: 1)
                if pair.count == 2 { values[String(pair[0])] = String(pair[1]) }
            }
            guard let address = IPAddress(values["ip"] ?? "") else { throw LookupError.invalidIP }
            var result = Intelligence(address: address, providerName: id.name, fetchedAt: date)
            result.countryCode = values["loc"]
            return result
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["success"] as? Bool != false,
              json["error"] == nil || json["error"] as? Bool == false else { throw LookupError.malformed }
        func value(_ path: String) -> Any? {
            var current: Any? = json
            for key in path.split(separator: ".") { current = (current as? [String: Any])?[String(key)] }
            return current
        }
        func string(_ path: String) -> String? {
            if let s = value(path) as? String, !s.isEmpty { return s }
            if let n = value(path) as? NSNumber { return n.stringValue }
            return nil
        }
        func number(_ path: String) -> Double? { string(path).flatMap(Double.init) }
        guard let address = IPAddress(string(id == .freeipapi ? "ipAddress" : "ip") ?? "") else { throw LookupError.invalidIP }
        var r = Intelligence(address: address, providerName: id.name, fetchedAt: date)
        switch id {
        case .ipwho:
            r.countryName = string("country"); r.countryCode = string("country_code"); r.region = string("region"); r.city = string("city"); r.postalCode = string("postal"); r.latitude = number("latitude"); r.longitude = number("longitude"); r.timezone = string("timezone.id"); r.utcOffset = string("timezone.utc"); r.isp = string("connection.isp"); r.organization = string("connection.org"); r.asn = string("connection.asn")
        case .ipinfo:
            r.countryCode = string("country"); r.region = string("region"); r.city = string("city"); r.postalCode = string("postal"); r.timezone = string("timezone"); r.organization = string("org")
            if let org = r.organization, org.hasPrefix("AS") { r.asn = org.split(separator: " ").first.map(String.init) }
            let location = (string("loc") ?? "").split(separator: ",")
            if location.count == 2 { r.latitude = Double(location[0]); r.longitude = Double(location[1]) }
        case .ipapi:
            r.countryName = string("country_name"); r.countryCode = string("country_code"); r.region = string("region"); r.city = string("city"); r.postalCode = string("postal"); r.latitude = number("latitude"); r.longitude = number("longitude"); r.timezone = string("timezone"); r.utcOffset = string("utc_offset"); r.organization = string("org"); r.asn = string("asn")
        case .geojs:
            r.countryName = string("country"); r.countryCode = string("country_code"); r.region = string("region"); r.city = string("city"); r.latitude = number("latitude"); r.longitude = number("longitude"); r.timezone = string("timezone"); r.organization = string("organization_name"); r.asn = string("asn")
        case .freeipapi:
            r.countryName = string("countryName"); r.countryCode = string("countryCode"); r.region = string("regionName"); r.city = string("cityName"); r.postalCode = string("zipCode"); r.latitude = number("latitude"); r.longitude = number("longitude"); r.timezone = (value("timeZones") as? [String])?.first
        default: break
        }
        if let latitude = r.latitude, !(-90...90).contains(latitude) { r.latitude = nil }
        if let longitude = r.longitude, !(-180...180).contains(longitude) { r.longitude = nil }
        return r
    }
}
