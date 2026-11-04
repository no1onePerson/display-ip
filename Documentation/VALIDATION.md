# Validation and remaining work

## Executed in the Linux cloud environment

- Swift 6.0.3 official toolchain installed over verified HTTPS.
- `swift test --package-path macOS --jobs 2`: **15 tests passed, 0 failures** (10 XCTest, 5 Swift Testing).
- Core tests cover all eight parsers with IPv4/IPv6, malformed responses, missing fields, IP normalization, family-independent confirmation, duplicate event suppression, HTTP 500 fallback, timeouts, 429/Retry-After, cooldowns, circuit recovery, cache, deduplication, cancellation, offline rejection, notification policy, history retention/export/serialization, isolated settings persistence, and widget serialization.
- Native Swift source syntax parsing passed. This is not Apple-framework type checking or compilation.
- Workflow YAML parsed, packaging shell syntax checked, project generation exercised.

## External blockers

- Linux cannot compile/link AppKit, SwiftUI, UserNotifications, ServiceManagement, or WidgetKit targets, launch the application, or produce a real macOS DMG.
- GitHub Actions API access returned HTTP 403. Git transport can push, but Actions results/artifact availability cannot currently be verified from this session.
- Provider/documentation domains returned proxy HTTP 403; real response and current terms verification remain pending.
- No Apple Developer certificate, App Group provisioning profiles, or notarization credentials are configured.

## Native release gates still unverified

Build both architectures and widget; run the core tests on macOS; inspect native bundle, entitlements, and App Group sharing; verify login approval, notification authorization/denial/revocation, first launch, repeated sleep/wake, offline recovery, sound volume, privacy mode, export permissions, and widget deep links. Inspect layout with real IPv6 values in light/dark, high contrast, Reduce Motion, Reduce Transparency, and VoiceOver. Capture real screenshots only after running the app. Measure memory, idle CPU, wakeups, and request frequency; no performance numbers are claimed.

## Current feature limits

- VPN/proxy/hosting, DNS servers, and local interface addresses are not classified; UI explicitly says unknown where appropriate.
- No discovery-only geolocation enrichment, independent country/ISP-change alerts, provider-outage alerts, customizable global shortcuts, accessory widgets, map, event detail window, or local analytics beyond total history count.
- Location confidence/UTC offsets are provider-dependent; missing fields remain absent.
- Menu item remains visible to keep the application reachable. No automatic update installer or translations are included.
- Budget and provider-health statistics reset when the application restarts. Separate IPv6 lookup currently has independent budgets and does not expose its diagnostics in the main provider list.
- Last observed family addresses may remain cached when a family becomes unavailable. A cached IPv6 value does not prove current IPv6 connectivity.
- Settings tests exercise persistence, not full UI interaction. Notification tests verify decisions, not OS delivery. Widget tests verify serialization, not WidgetKit execution.
- Generated icons are real assets; no fabricated application screenshots are used.

The project is a development preview, not complete against the production acceptance criteria until the native release gates pass.
