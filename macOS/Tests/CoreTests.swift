import XCTest
@testable import PrismCore

final class CoreTests: XCTestCase {
    func testCanonicalAddresses() {
        XCTAssertEqual(IPAddress("2001:0db8:0000::1")?.value, "2001:db8::1")
        XCTAssertEqual(IPAddress("192.0.2.1\n")?.family, .v4)
        XCTAssertNil(IPAddress("999.0.0.1")); XCTAssertNil(IPAddress("hello"))
    }
    func testEveryProvider() throws {
        let fixtures: [ProviderID: String] = [
            .ipwho: #"{"ip":"192.0.2.1","country_code":"DE","connection":{"asn":64500,"isp":"Example"},"timezone":{"id":"Europe/Berlin"}}"#,
            .ipinfo: #"{"ip":"192.0.2.1","country":"DE","loc":"52.5,13.4","org":"AS64500 Example"}"#,
            .ipapi: #"{"ip":"192.0.2.1","country_code":"DE","country_name":"Germany"}"#,
            .geojs: #"{"ip":"192.0.2.1","country_code":"DE","latitude":"52.5","asn":64500}"#,
            .freeipapi: #"{"ipAddress":"192.0.2.1","countryCode":"DE","timeZones":["Europe/Berlin"]}"#,
            .ipify: #"{"ip":"192.0.2.1"}"#,
            .icanhazip: "192.0.2.1\n", .cloudflare: "ip=192.0.2.1\nloc=DE\nwarp=off\n"
        ]
        for id in ProviderID.allCases {
            let data = Data(try XCTUnwrap(fixtures[id]).utf8)
            XCTAssertEqual(try ProviderAdapter(id).parse(data).address.value, "192.0.2.1")
            let v6 = String(decoding: data, as: UTF8.self).replacingOccurrences(of: "192.0.2.1", with: "2001:db8::1")
            XCTAssertEqual(try ProviderAdapter(id).parse(Data(v6.utf8)).address.family, .v6)
            XCTAssertThrowsError(try ProviderAdapter(id).parse(Data("invalid".utf8)))
        }
    }
    func testOptionalFieldsAndErrors() throws {
        let result = try ProviderAdapter(.ipinfo).parse(Data(#"{"ip":"192.0.2.1"}"#.utf8))
        XCTAssertNil(result.city); XCTAssertNil(result.organization)
        XCTAssertThrowsError(try ProviderAdapter(.ipwho).parse(Data(#"{"ip":"192.0.2.1","success":false}"#.utf8)))
        XCTAssertThrowsError(try ProviderAdapter(.ipapi).parse(Data(#"{"ip":"bad"}"#.utf8)))
    }
    func testFamilyIndependentConfirmation() throws {
        var detector = ChangeDetector()
        func info(_ ip: String) throws -> Intelligence { Intelligence(address: try XCTUnwrap(IPAddress(ip)), providerName: "Test") }
        XCTAssertNil(detector.observe(try info("192.0.2.1")))
        XCTAssertNil(detector.observe(try info("2001:db8::1")))
        XCTAssertNil(detector.observe(try info("192.0.2.2")))
        XCTAssertNotNil(detector.observe(try info("192.0.2.2")))
        XCTAssertNil(detector.observe(try info("192.0.2.2")))
        XCTAssertNil(detector.observe(try info("2001:0db8:0::1")))
    }
    func testQuietHoursAndDuplicates() {
        var policy = NotificationPolicy(); policy.enabled = true; policy.quietEnabled = true
        XCTAssertFalse(policy.permits(key: "change", at: Date(), hour: 23))
        XCTAssertTrue(policy.permits(key: "change", at: Date(), hour: 12))
        XCTAssertFalse(policy.permits(key: "change", at: Date(), hour: 12))
    }
    func testRetryAfter() {
        XCTAssertEqual(ProviderManager.retryDelay("120", now: Date()), 120)
        XCTAssertEqual(ProviderManager.retryDelay("Thu, 01 Jan 1970 00:02:00 GMT", now: Date(timeIntervalSince1970: 0)), 120)
        XCTAssertNil(ProviderManager.retryDelay("bad", now: Date()))
    }
    func testSerializationRetentionAndCSV() throws {
        let info = Intelligence(address: try XCTUnwrap(IPAddress("192.0.2.2")), providerName: "Example, Provider")
        let event = ChangeEvent(date: Date(), previous: try XCTUnwrap(IPAddress("192.0.2.1")), current: info, reason: "Confirmed", confirmed: true)
        XCTAssertEqual(try JSONDecoder().decode(ChangeEvent.self, from: JSONEncoder().encode(event)), event)
        XCTAssertTrue(HistoryStore.csv([event]).contains("\"Example, Provider\""))
        XCTAssertEqual(HistoryStore.retain([event], days: 30, now: Date().addingTimeInterval(31 * 86400)).count, 0)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = HistoryStore(url: url); try store.save([event]); XCTAssertEqual(try store.load(), [event])
    }
}
actor MockTransport: HTTPTransport {
    var requests = 0
    let results: [HTTPResult]
    init(_ results: [HTTPResult]) { self.results = results }
    func fetch(_ url: URL, timeout: TimeInterval) async throws -> HTTPResult {
        let index = requests; requests += 1
        try await Task.sleep(for: .milliseconds(20))
        guard index < results.count else { throw URLError(.timedOut) }
        return results[index]
    }
}
final class ManagerTests: XCTestCase {
    func testFallbackCachingAndDeduplication() async throws {
        let mock = MockTransport([HTTPResult(data: Data(), status: 500), HTTPResult(data: Data(#"{"ip":"192.0.2.1"}"#.utf8), status: 200)])
        let manager = ProviderManager(transport: mock)
        async let a = manager.lookup(priority: [.ipwho, .ipinfo])
        async let b = manager.lookup(priority: [.ipwho, .ipinfo])
        let (first, second) = try await (a, b)
        XCTAssertEqual(first, second)
        let cached = try await manager.lookup(priority: [.ipwho, .ipinfo]); XCTAssertEqual(first, cached)
        let count = await mock.requests; XCTAssertEqual(count, 2)
        let health = await manager.diagnostics(); XCTAssertEqual(health[.ipwho]?.failures, 1)
    }
    func testRateLimitCooldownAndOffline() async throws {
        let start = Date()
        let mock = MockTransport([HTTPResult(data: Data(), status: 429, retryAfter: "600")])
        let manager = ProviderManager(transport: mock, now: { start }, jitter: { 0 })
        do { _ = try await manager.lookup(priority: [.ipwho]); XCTFail() } catch {}
        do { _ = try await manager.lookup(priority: [.ipwho], force: true); XCTFail() } catch {}
        do { _ = try await manager.lookup(online: false); XCTFail() } catch { XCTAssertEqual(error as? LookupError, .offline) }
        let count = await mock.requests; XCTAssertEqual(count, 1)
        let health = await manager.diagnostics(); XCTAssertEqual(health[.ipwho]?.nextAllowed, start.addingTimeInterval(600))
    }
    func testTimeout() async {
        let manager = ProviderManager(transport: MockTransport([]))
        do { _ = try await manager.lookup(priority: [.ipwho]); XCTFail() } catch {}
        let health = await manager.diagnostics(); XCTAssertEqual(health[.ipwho]?.failures, 1)
    }
}
