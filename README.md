# IP Prism for macOS

A native menu bar companion that puts your public connection in focus. Built with Swift 6, SwiftUI, Network.framework, and WidgetKit. macOS 14 or newer; no account or API key required for the basic provider flow.

**Development preview.** The portable Swift core passes 15 deterministic tests on Linux. Native targets, permissions, widget sharing, and packaging still require successful macOS CI and runtime verification. This is not yet a verified production release. No screenshots are included because the native application has not been run in this environment.

## Features implemented

- Frosted system-material panel with Overview, Network, Location, Providers, and History sections.
- Eight provider adapters, optional fields, automatic fallback or manual selection, priority and enable controls.
- Timeouts, jittered backoff, Retry-After, cooldowns, circuit breaker, budgets, deduplication, caching, cancellation, and health diagnostics.
- Normalized IPv4/IPv6, independent family comparison, two-observation change confirmation, optional IPv6-only discovery.
- Network-change debounce, sleep/wake scheduling, offline cache, configurable polling.
- Local history with retention, search, JSON/CSV export, and deletion.
- Contextual notifications, permission state, quiet hours, privacy mode, and synthesized original sounds.
- Login-item controls using SMAppService; Keychain storage for an optional IPinfo token.
- Small, medium, and large desktop widgets using sanitized App Group state.
- Adjustable menu bar formatting, native monochrome symbol, appearance controls, and optional onboarding.

See [known limitations and verification](Documentation/VALIDATION.md) before relying on the preview.

## Install

Download a successful build from [Releases](https://github.com/no1onePerson/display-ip/releases). Open `IPPrism.dmg`, drag **IP Prism.app** to **Applications**, and launch it. The app appears in the menu bar. `IPPrism.zip` is also provided when the release workflow succeeds.

Read the release's signing status. Development artifacts are ad-hoc signed, not Apple-notarized; Gatekeeper can block them. Do not disable Gatekeeper. Signed distribution requires the provisioning and notarization setup described in [Release instructions](Documentation/RELEASE.md).

Add desktop widgets using macOS **Edit Widgets → IP Prism**. Keep the application running to refresh cached data. WidgetKit controls delivery timing; widgets are not continuously live. Both targets must have the same provisioned App Group for reliable sharing.

## Development

Open `macOS/IPPrism.xcodeproj` in Xcode 16.4 or newer. Choose the IPPrism scheme and your team. Register or replace the app and widget identifiers and shared App Group before signing. The generated project is committed and has no third-party runtime dependencies.

```sh
# Portable core, on macOS or Linux with Swift 6:
swift test --package-path macOS

# Reproduce the committed project (Python 3):
python3 Scripts/generate-project.py

# Build both native targets on macOS:
xcodebuild -project macOS/IPPrism.xcodeproj -scheme IPPrism \
  -configuration Debug -derivedDataPath macOS/build CODE_SIGNING_ALLOWED=NO build
```

The project generator is the source of truth for bundle identifiers, version, entitlements, and file membership. Run it after adding native source files. App icon artwork can be regenerated with `python3 Scripts/generate-icon.py` (development-only dependency: Pillow).

## Privacy and providers

No analytics SDK, account, precise location permission, Accessibility permission, or privileged helper. Contacted providers necessarily receive your public IP. History and the latest lookup are stored locally; widgets receive a sanitized cache. IP-based location is approximate and does not establish a person's physical position.

Adapters: **IPWho.is, IPinfo, ipapi.co, GeoJS, FreeIPAPI, ipify, icanhazip, Cloudflare Trace**. Their capabilities differ; discovery-only services do not supply city/ISP details. Providers' current terms and quotas require live verification before stable distribution. [Provider reference](Documentation/PROVIDERS.md) · [Privacy policy](PRIVACY.md).

## Troubleshooting

- **No result:** check Providers for failures/cooldowns. Free endpoints may rate-limit or change behavior. Last successful data remains visible.
- **No IPv6:** enable separate IPv6 discovery; your network must support IPv6. Missing IPv6 is not a confirmed change.
- **No notifications:** enable them in Settings, grant macOS authorization, and check quiet hours and event toggles.
- **Login approval required:** open the system Login Items page from Settings.
- **Widget empty:** launch the app, complete a successful lookup, and verify matching App Group provisioning for both bundles.
- **No location or ISP:** the responding provider may not supply those fields.
- **Release build failed:** inspect [Actions](https://github.com/no1onePerson/display-ip/actions); artifact creation is gated on a successful build.

The earlier Node prototype remains as historical source; it is not part of the native build.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md), [architecture](Documentation/ARCHITECTURE.md), and [security policy](SECURITY.md). MIT licensed. No commercial Apple assets or third-party sound recordings are included.
