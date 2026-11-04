# Display IP for macOS

Native SwiftUI menu bar app with a translucent connection panel, public IP details, automatic provider fallback, network-change refresh, clipboard copying, login-item controls, IP-change notifications, and a WidgetKit extension. Requires macOS 14 or later.

## Download

Tagged builds create a prerelease on [GitHub Releases](https://github.com/no1onePerson/display-ip/releases). Download `DisplayIP.dmg`, open it, and drag DisplayIP into Applications. Preview builds are ad-hoc signed, **not notarized**. Gatekeeper may block them. A signed, notarized release needs an Apple Developer account and distribution credentials; widget App Group access also needs correctly provisioned signing. No completed macOS build or release is claimed until Actions succeeds.

## Build on a Mac

Install Xcode and XcodeGen (`brew install xcodegen`). Then:

```sh
cd macOS
xcodegen generate
open DisplayIP.xcodeproj
```

Select your development team for both targets. Replace the bundle IDs and `group.com.displayip.shared` in project.yml and Shared/Snapshot.swift with your team's registered identifiers. Enable the matching App Group on both targets. Build and run the DisplayIP scheme. Add the widget through macOS's Edit Widgets interface. WidgetKit schedules updates; it is not a real-time view. The widget shows the app's last successful lookup.

## Providers

Seven HTTPS adapters: ipwho.is, IPinfo, ipapi.co, IPWhois.app, FreeIPAPI, ipapi.is, and GeoJS. Preferred provider is attempted first; failures fall back sequentially, with an 8-second timeout per request. Each provider has independent availability, limits, and terms; these public endpoints are not guaranteed production service. Provider diagnostics appear in the panel. Only the selected connection's returned address is shown; simultaneous IPv4 and IPv6 lookup is not implemented.

## Permissions and privacy

Notification authorization is requested only when you enable IP-change notifications. Login startup uses Apple's SMAppService and may require approval in System Settings → General → Login Items. App Sandbox permits outbound networking. No location, accessibility, or administrator permission is requested. Providers receive your public IP when contacted. The latest result is stored locally in the shared App Group for the widget; there is no analytics or historical database.

## Validation status

This repository was developed in a Linux cloud environment without Xcode. Native compilation, runtime behavior, permission dialogs, animation, accessibility, and widget sharing require macOS validation. The GitHub workflow builds a universal binary and verifies its ad-hoc signature before packaging. Before stable release, verify fallback and offline behavior, network/VPN changes, login approval, notification denial/revocation, restart, both widget sizes, Reduce Motion, and light/dark appearance on a real Mac.

The earlier web prototype remains in `public/` and `server.js`; the native product is under `macOS/`.
