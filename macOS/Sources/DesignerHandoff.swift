enum DesignerHandoff {
    static let text = """
    IpBan — macOS menu bar IP monitor

    Purpose: provide a quick, privacy-conscious view of public internet addresses and connection details. Native SwiftUI menu bar app, macOS 14+. IP-based location is approximate.

    Menu bar: one chosen IPv4 or IPv6 address; modes include address, flag plus address, country plus address, flag only, monochrome icon, ISP abbreviation, and custom tokens. Long addresses can be shortened. Privacy mode hides sensitive information.

    Overview tab: IPv4 and IPv6 independently (or unavailable), separate copy buttons, approximate city/country and flag, network/organization, provider, last successful update, cached/stale warning, refresh and copy feedback.

    Network tab: IPv4, IPv6, active interface type, ISP, organization, ASN, and VPN/proxy evidence status. Unknown is not a diagnosis.

    Location tab: country, region, city, postal code, time zone, optional coordinates, and an approximate-location explanation.

    Providers tab: provider names, discovery/location capabilities, successes, failures, last latency, cooldown and error status. Eight services; automatic fallback or manual choice. Missing data must never be invented.

    History tab: searchable chronological confirmed IP changes with previous/current addresses, timestamp and reason. Changes need two consecutive matching observations. IPv4 and IPv6 are compared independently.

    Designer tab: this copyable specification; contains no user's addresses, location, or credentials.

    Persistent controls: top header with connection status and Settings; bottom refresh, copy and quit actions. States include first-run onboarding, online, offline, loading, error, unavailable values, cached/stale results, copy confirmation, privacy mode, and empty history.

    Widget: small, medium and large; last cached address, connection state, update age, and location/provider details where space permits. Widget updates are scheduled by macOS; not live. Private mode removes sensitive cached widget data.

    Settings sections: General (login item, appearance, polling, IPv6 lookup); Menu Bar (format, compact mode, preferred family); Providers (automatic/manual, enable/priority, timeout, optional IPinfo Keychain token, test/reset); Notifications (OS permission, IP and connection toggles, quiet hours); Sounds (opt-in, six synthesized choices, volume and preview); History (retention, CSV/JSON export, clear); Privacy (hide sensitive data, delete cache/history); Security (kill switch unavailable); About (version, repository and license).

    Permissions: notifications are requested only after opt-in; launch at login is user controlled; outgoing provider requests reveal the user's public IP to that provider. No location permission, hidden telemetry or account is required. A system-wide network kill switch is not implemented.

    Design: native translucent system materials, subtle cyan/violet gradient, rounded cards and typography, SF Symbols, small animations that respect Reduce Motion, and fallback for Reduce Transparency. Support light/dark, VoiceOver, keyboard access, long IPv6 strings, non-English layouts and low contrast sensitivity.

    Deliverables requested from a designer: menu bar states, popover tabs and all empty/error/loading/privacy states, standalone settings window and each section, onboarding, widgets in three sizes, notification and copy feedback, system approval and recovery flows for a future network kill switch. Provide component spacing, typography, colors, interaction states, motion durations and accessible contrast specifications. Do not present conceptual mockups as screenshots of the current app.
    """
}
