# Validation and remaining work

## Executed in the Linux cloud environment

- Swift 6.0.3 official toolchain installed over verified HTTPS.
- `swift test --package-path macOS --jobs 2`: **16 tests passed, 0 failures** (10 XCTest, 6 Swift Testing).
- Core tests cover all eight parsers with IPv4/IPv6, malformed responses, missing fields, IP normalization, family-independent confirmation, duplicate event suppression, HTTP 500 fallback, timeouts, 429/Retry-After, cooldowns, circuit recovery, cache, deduplication, cancellation, offline rejection, notification policy, history retention/export/serialization, isolated settings persistence, and widget serialization.
- Native Swift source syntax parsing passed. This is not Apple-framework type checking or compilation.
- Workflow YAML parsed, packaging shell syntax checked, project generation exercised.

## macOS CI: 0.4.0-preview.1

- Release workflow passed on macOS: portable core tests, universal Release app and widget build, bundle/plist checks, ad-hoc signature verification, DMG mount and Applications shortcut, ZIP extraction, and checksums.
- The settings-window smoke test opens, closes, and reopens the retained AppKit window through the same deferred opener the menu bar gear uses. It still does not click the gear inside MenuBarExtra, and it does not establish that every settings control works or that the menu bar presentation is visually correct.
- Downloaded the published DMG and ZIP into Linux and verified both published SHA-256 checksums, ZIP integrity, app and widget bundle IDs/version, app icon, and both Mach-O architectures.
- No Apple Developer ID or notarization credentials were available. The preview is ad-hoc signed, not notarized.

## External blockers

- This Linux workspace cannot compile/link AppKit, SwiftUI, UserNotifications, ServiceManagement, or WidgetKit targets or launch the application locally; the GitHub macOS runner built and packaged the preview.
- GitHub Actions API access returned HTTP 403. Public run summaries are accessible through the GitHub website; full logs and authenticated artifact access may still require repository access.
- Provider/documentation domains returned proxy HTTP 403; real response and current terms verification remain pending.
- No Apple Developer certificate, App Group provisioning profiles, or notarization credentials are configured.

## Native release gates still unverified

Verify signed entitlements and App Group sharing; verify login approval, notification authorization/denial/revocation, first launch, repeated sleep/wake, offline recovery, sound volume, privacy mode, export permissions, and widget deep links. Inspect layout with real IPv6 values in light/dark, high contrast, Reduce Motion, Reduce Transparency, and VoiceOver. Capture real screenshots only after running the app. Measure memory, idle CPU, wakeups, and request frequency; no performance numbers are claimed.

## Current feature limits

- VPN/proxy/hosting, DNS servers, and local interface addresses are not classified; UI explicitly says unknown where appropriate.
- No discovery-only geolocation enrichment, independent country/ISP-change alerts, provider-outage alerts, customizable global shortcuts, accessory widgets, map, event detail window, or local analytics beyond total history count.
- Location confidence/UTC offsets are provider-dependent; missing fields remain absent.
- Menu item remains visible to keep the application reachable. No automatic update installer or translations are included.
- Separate IPv6 lookup has independent persisted budgets and does not expose its diagnostics in the main provider list. Disk persistence failure leaves only current-session budget enforcement.
- Last observed family addresses may remain cached when a family becomes unavailable. A cached IPv6 value does not prove current IPv6 connectivity.
- Settings tests exercise persistence, not full UI interaction. Notification tests verify decisions, not OS delivery. Widget tests verify serialization, not WidgetKit execution.
- Generated icons are real assets; no fabricated application screenshots are used.

The project is a development preview, not complete against the production acceptance criteria until the native release gates pass.
