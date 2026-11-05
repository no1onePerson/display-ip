import AppKit
import AVFoundation
import Security
import UserNotifications
import PrismCore

@MainActor final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    var policy = NotificationPolicy()
    var onOpen: (() -> Void)?
    override init() { super.init(); UNUserNotificationCenter.current().delegate = self }
    func permission() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
    func request() async throws -> Bool {
        let status = await permission()
        if status == .notDetermined { return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
        return status == .authorized || status == .provisional
    }
    func send(key: String, title: String, detail: String) async -> Bool {
        let defaults = UserDefaults.standard
        policy.enabled = defaults.bool(forKey: "notify")
        policy.quietEnabled = defaults.bool(forKey: "quiet")
        policy.quietStart = defaults.integer(forKey: "quietStart"); policy.quietEnd = defaults.integer(forKey: "quietEnd")
        let status = await permission()
        guard status == .authorized || status == .provisional,
              policy.permits(key: key, at: Date(), hour: Calendar.current.component(.hour, from: Date())) else { return false }
        let content = UNMutableNotificationContent(); content.title = title
        content.body = defaults.bool(forKey: "privacy") ? "Open IpBan for details." : detail
        do { try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: key, content: content, trigger: nil)); return true }
        catch { return false }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { self.onOpen?() }
    }
}

@MainActor final class SoundService {
    static let presets = ["Crystal Pulse", "Soft Glass", "Digital Bloom", "Aurora", "Minimal Click", "Silent"]
    private var player: AVAudioPlayer?
    private var lastPlayed = Date.distantPast
    func play(preview: Bool = false) {
        let d = UserDefaults.standard
        let name = d.string(forKey: "soundPreset") ?? "Crystal Pulse"
        var quiet = NotificationPolicy(); quiet.quietEnabled = d.bool(forKey: "quiet"); quiet.quietStart = d.integer(forKey: "quietStart"); quiet.quietEnd = d.integer(forKey: "quietEnd")
        guard name != "Silent", (preview || d.bool(forKey: "sound")),
              !quiet.isQuiet(hour: Calendar.current.component(.hour, from: Date())),
              preview || Date().timeIntervalSince(lastPlayed) > 10 else { return }
        let index = Self.presets.firstIndex(of: name) ?? 0
        let rate = 22050, count = index == 4 ? 2205 : 11025
        var pcm = Data()
        for sample in 0..<count {
            let t = Double(sample) / Double(rate)
            let attack = min(1, t / 0.012)
            let fade = pow(max(0, 1 - Double(sample) / Double(count)), 3)
            let frequency = [880.0, 660, 740, 520, 1100][min(index, 4)]
            let tone = sin(2 * .pi * frequency * t) + 0.28 * sin(2 * .pi * frequency * 1.5 * t)
            var value = Int16(tone * attack * fade * 14000).littleEndian
            withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
        }
        var wav = Data("RIFF".utf8)
        func append<T: FixedWidthInteger>(_ value: T) { var little = value.littleEndian; withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) } }
        append(UInt32(pcm.count + 36)); wav.append(Data("WAVEfmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1)); append(UInt32(rate)); append(UInt32(rate * 2)); append(UInt16(2)); append(UInt16(16)); wav.append(Data("data".utf8)); append(UInt32(pcm.count)); wav.append(pcm)
        do { player = try AVAudioPlayer(data: wav); player?.volume = Float(d.double(forKey: "volume")); player?.play(); lastPlayed = Date() } catch { player = nil }
    }
}

enum KeychainStore {
    static func set(_ secret: String, account: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "IPPrism", kSecAttrAccount as String: account]
        let deletion = SecItemDelete(query as CFDictionary)
        guard deletion == errSecSuccess || deletion == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(deletion)) }
        if secret.isEmpty { return }
        var item = query; item[kSecValueData as String] = Data(secret.utf8); item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
}

extension KeychainStore {
    static func get(account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "IPPrism", kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
struct CredentialTransport: HTTPTransport {
    func fetch(_ url: URL, timeout: TimeInterval) async throws -> HTTPResult {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        if url.host == "ipinfo.io", let token = KeychainStore.get(account: "IPinfo"), !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw LookupError.malformed }
        return HTTPResult(data: data, status: response.statusCode, retryAfter: response.value(forHTTPHeaderField: "Retry-After"))
    }
}
