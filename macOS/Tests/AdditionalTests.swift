import Foundation
import Testing
@testable import PrismCore
@testable import PrismShared

@Test func widgetRoundTrip() throws {
    let snapshot = Snapshot(ipv4: "192.0.2.1", ipv6: "2001:db8::1", country: "DE", city: "Example", organization: nil, provider: "Test", date: Date(), online: true, privateMode: false)
    let decoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(snapshot))
    #expect(decoded.ipv4 == snapshot.ipv4)
    #expect(decoded.ipv6 == snapshot.ipv6)
    #expect(decoded.date == snapshot.date)
}
@Test func settingsPersistInIsolatedSuite() throws {
    let name = "IpBan.Tests.\(UUID())"
    let first = try #require(UserDefaults(suiteName: name))
    defer { first.removePersistentDomain(forName: name) }
    first.set(120, forKey: "interval"); first.set(true, forKey: "privacy")
    let second = try #require(UserDefaults(suiteName: name))
    #expect(second.integer(forKey: "interval") == 120)
    #expect(second.bool(forKey: "privacy"))
}
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var date = Date(timeIntervalSince1970: 10000)
    func now() -> Date { lock.lock(); defer { lock.unlock() }; return date }
    func advance(_ seconds: TimeInterval) { lock.lock(); defer { lock.unlock() }; date.addTimeInterval(seconds) }
}
@Test func circuitBreakerAndRecovery() async throws {
    let clock = TestClock()
    let mock = MockTransport([HTTPResult(data: Data(), status: 500), HTTPResult(data: Data(), status: 500), HTTPResult(data: Data(), status: 500), HTTPResult(data: Data(#"{"ip":"192.0.2.1"}"#.utf8), status: 200)])
    let manager = ProviderManager(transport: mock, now: { clock.now() }, jitter: { 0 })
    for _ in 0..<3 {
        do { _ = try await manager.lookup(priority: [.ipify], force: true); Issue.record("Expected failure") } catch {}
        clock.advance(130)
    }
    do { _ = try await manager.lookup(priority: [.ipify], force: true); Issue.record("Circuit should be open") } catch {}
    #expect(await mock.requests == 3)
    clock.advance(300)
    let result = try await manager.lookup(priority: [.ipify], force: true)
    #expect(result.address.value == "192.0.2.1")
    #expect(await manager.diagnostics()[.ipify]?.consecutiveFailures == 0)
}
@Test func cancellationStopsFallback() async {
    let mock = MockTransport([])
    let manager = ProviderManager(transport: mock)
    let task = Task { try await manager.lookup() }
    try? await Task.sleep(for: .milliseconds(5))
    await manager.cancel()
    do { _ = try await task.value; Issue.record("Expected cancellation") } catch {}
    #expect(await mock.requests <= 1)
}
@Test func invalidFlagsAreNotFabricated() throws {
    var data = Intelligence(address: try #require(IPAddress("192.0.2.1")), providerName: "Test")
    data.countryCode = "Germany"; #expect(data.flag.isEmpty)
    data.countryCode = "12"; #expect(data.flag.isEmpty)
    data.countryCode = "de"; #expect(data.flag == "🇩🇪")
}
@Test func budgetPersistsAcrossManagers() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let clock = TestClock()
    let mock = MockTransport([HTTPResult(data: Data(), status: 429, retryAfter: "600")])
    let first = ProviderManager(transport: mock, now: { clock.now() }, stateURL: url)
    do { _ = try await first.lookup(priority: [.ipify]); Issue.record("Expected rate limit") } catch {}
    let second = ProviderManager(transport: mock, now: { clock.now() }, stateURL: url)
    do { _ = try await second.lookup(priority: [.ipify]); Issue.record("Expected persisted cooldown") } catch {}
    #expect(await mock.requests == 1)
}
