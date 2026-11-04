import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct HTTPResult: Sendable {
    public let data: Data
    public let status: Int
    public let retryAfter: String?
    public init(data: Data, status: Int, retryAfter: String? = nil) { self.data = data; self.status = status; self.retryAfter = retryAfter }
}
public protocol HTTPTransport: Sendable { func fetch(_ url: URL, timeout: TimeInterval) async throws -> HTTPResult }
public struct URLSessionTransport: HTTPTransport {
    public init() {}
    public func fetch(_ url: URL, timeout: TimeInterval) async throws -> HTTPResult {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.setValue("IPPrism/0.3", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LookupError.malformed }
        return HTTPResult(data: data, status: http.statusCode, retryAfter: http.value(forHTTPHeaderField: "Retry-After"))
    }
}
public struct ProviderHealth: Codable, Sendable {
    public var successes = 0, failures = 0, consecutiveFailures = 0, requests = 0
    public var latency: TimeInterval?, lastSuccess: Date?, nextAllowed: Date?, lastError: String?
    public var windowStart = Date()
    public var score: Double { Double(successes + 1) / Double(successes + failures + 1) }
    public init() {}
}
public actor ProviderManager {
    private let transport: any HTTPTransport
    private let now: @Sendable () -> Date
    private let jitter: @Sendable () -> Double
    private let stateURL: URL?
    private var health: [ProviderID: ProviderHealth] = [:]
    private var cache: [String: Intelligence] = [:]
    private var flights: [String: (id: UUID, task: Task<Intelligence, Error>)] = [:]
    public init(transport: any HTTPTransport = URLSessionTransport(), now: @escaping @Sendable () -> Date = { Date() }, jitter: @escaping @Sendable () -> Double = { Double.random(in: 0...1) }, stateURL: URL? = nil) {
        self.transport = transport; self.now = now; self.jitter = jitter; self.stateURL = stateURL
        if let stateURL, let data = try? Data(contentsOf: stateURL), let restored = try? JSONDecoder().decode([ProviderID: ProviderHealth].self, from: data) { self.health = restored }
    }
    private func persist() {
        guard let stateURL else { return }
        do { try FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true); try JSONEncoder().encode(health).write(to: stateURL, options: .atomic) } catch { /* A disk failure must not crash networking; current-session limits remain enforced. */ }
    }
    public func diagnostics() -> [ProviderID: ProviderHealth] { health }
    public func resetStatistics() { for id in health.keys { var fresh = ProviderHealth(); fresh.nextAllowed = health[id]?.nextAllowed; fresh.requests = health[id]?.requests ?? 0; fresh.windowStart = health[id]?.windowStart ?? now(); health[id] = fresh }; persist() }
    public func cancel() { for flight in flights.values { flight.task.cancel() }; flights.removeAll() }
    public func lookup(priority: [ProviderID] = ProviderID.allCases, timeout: TimeInterval = 8, force: Bool = false, online: Bool = true, family: Family? = nil) async throws -> Intelligence {
        guard online else { throw LookupError.offline }
        let key = (family?.rawValue ?? "any") + priority.map(\.rawValue).joined(separator: ",")
        if let flight = flights[key] { return try await flight.task.value }
        if !force, let cached = cache[key], now().timeIntervalSince(cached.fetchedAt) < 30 { return cached }
        let task = Task { try await self.perform(priority: priority, timeout: timeout, family: family) }
        let identifier = UUID()
        flights[key] = (identifier, task)
        defer { if flights[key]?.id == identifier { flights[key] = nil } }
        let result = try await task.value
        cache[key] = result
        return result
    }
    private func perform(priority: [ProviderID], timeout: TimeInterval, family: Family?) async throws -> Intelligence {
        for id in priority {
            try Task.checkCancellation()
            let start = now()
            var h = health[id] ?? ProviderHealth()
            if start.timeIntervalSince(h.windowStart) >= 86400 { h.requests = 0; h.windowStart = start }
            if let next = h.nextAllowed, next > start { continue }
            // Conservative local budget; upstream limits still take precedence.
            if h.requests >= (id == .ipapi ? 500 : 1000) { continue }
            h.requests += 1; h.nextAllowed = start.addingTimeInterval(id.minimumInterval); health[id] = h; persist()
            do {
                let endpoint: String
                if family == .v6 {
                    guard id == .ipify || id == .icanhazip else { continue }
                    endpoint = id == .ipify ? "https://api6.ipify.org?format=json" : "https://ipv6.icanhazip.com/"
                } else { endpoint = id.endpoint }
                guard let url = URL(string: endpoint), url.scheme == "https" else { throw LookupError.malformed }
                let response = try await transport.fetch(url, timeout: max(2, min(timeout, 30)))
                if response.status == 429 {
                    h.nextAllowed = start.addingTimeInterval(max(id.minimumInterval, Self.retryDelay(response.retryAfter, now: start) ?? 300))
                    health[id] = h
                    throw LookupError.http(429)
                }
                guard (200..<300).contains(response.status) else { throw LookupError.http(response.status) }
                let result = try ProviderAdapter(id).parse(response.data, at: now())
                if let family, result.address.family != family { throw LookupError.invalidIP }
                try Task.checkCancellation()
                h.successes += 1; h.consecutiveFailures = 0; h.lastSuccess = now(); h.latency = now().timeIntervalSince(start); h.lastError = nil
                health[id] = h; persist()
                return result
            } catch {
                if Task.isCancelled { throw CancellationError() }
                h.failures += 1; h.consecutiveFailures += 1; h.lastError = String(describing: error)
                let backoff = min(3600, pow(2, Double(min(h.consecutiveFailures, 10))) * 15) * (1 + jitter() * 0.2)
                let circuit = h.consecutiveFailures >= 3 ? max(300, backoff) : backoff
                h.nextAllowed = max(h.nextAllowed ?? start, start.addingTimeInterval(circuit))
                health[id] = h; persist()
            }
        }
        throw LookupError.unavailable
    }
    public static func retryDelay(_ text: String?, now: Date) -> TimeInterval? {
        guard let text else { return nil }
        if let seconds = Double(text), seconds.isFinite { return max(0, seconds) }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.timeZone = TimeZone(secondsFromGMT: 0); formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter.date(from: text).map { max(0, $0.timeIntervalSince(now)) }
    }
}
