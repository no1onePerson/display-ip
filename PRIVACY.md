# Privacy policy

IpBan does not collect telemetry, analytics, accounts, or usage reports. It contacts selected public IP providers over HTTPS. Those services receive the internet address from which each request arrives and may process or log it under their own policies. Automatic fallback may contact multiple services if earlier requests fail. See Documentation/PROVIDERS.md for every endpoint and verification status.

The latest IP details and confirmed IP-change history are stored in the application's sandbox Application Support directory. Default history retention is 30 days. A sanitized latest snapshot is shared locally with the widget through an App Group. The optional IPinfo token is stored in macOS Keychain and sent only to IPinfo.

Privacy mode hides sensitive UI/notification values and strips them from the widget snapshot; it does not encrypt or delete local history. History exports deliberately contain real values. Delete history/cache through Settings. Removing a token requires saving an empty token in Providers. macOS controls notification permission and launch-at-login registration independently.

Geolocation is approximate IP-based information; no Core Location permission is requested. The application does not inspect unrelated traffic, request administrator rights, install privileged helpers, or require Accessibility, screen recording, or Full Disk Access permissions.

The operating system, GitHub distribution, and external providers have independent privacy policies. Stable distribution remains gated on reviewing current provider usage terms.
