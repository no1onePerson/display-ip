# Build, sign, and distribute

The committed project targets macOS 14, Swift 6, and both arm64/x86_64. CI uses Xcode 16.4 on macos-15. Main/PR workflows test the core, build native targets, and run Xcode analysis. Release tags must match the marketing version; the current pattern is `v0.4.0` or `v0.4.0-preview.N`. Update the generator and workflow together for a new version.

## Developer ID setup

Register your app and widget identifiers and the shared App Group with Apple. Replace `com.displayip.app`, `com.displayip.app.widget`, and `group.com.displayip.shared` with identifiers owned by your team in the project generator and Shared/Snapshot.swift. Regenerate the project and commit it. The current identifiers are placeholders, not a claim of registration.

Configure GitHub repository secrets securely:

- `DEVELOPER_ID_CERTIFICATE_BASE64`: base64 PKCS#12 Developer ID Application certificate/private key.
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`: certificate password.
- `DEVELOPER_ID_IDENTITY`: exact signing identity.
- `APPLE_ID`, `APPLE_APP_PASSWORD`, `APPLE_TEAM_ID`: notarization credentials.
- `APP_PROFILE_BASE64`, `WIDGET_PROFILE_BASE64`: matching Developer ID provisioning profiles authorizing the shared App Group.

The workflow imports credentials into a temporary keychain, archives Release, embeds profiles, signs the extension then app with Hardened Runtime, notarizes and staples the app, and verifies Gatekeeper acceptance. It then packages and notarizes/staples the DMG. Cleanup deletes temporary credential files/keychain. Missing partial signing configuration fails rather than silently claiming a signed release.

With no certificate configured, the workflow creates an **ad-hoc signed development preview**. It is not Apple notarized. App Group access and installation are not guaranteed in that mode. Do not disable Gatekeeper or advertise this mode as production distribution.

## Outputs and verification

`dist/IpBan.dmg`, `dist/IpBan.zip`, `dist/SHA256SUMS.txt` are produced only after a successful macOS build. Packaging verifies the app executable, embedded widget, plists, signature, ZIP extraction, DMG mount, Applications symlink, and checksum consistency. A signed run also requires notarization/stapling/Gatekeeper checks. The DMG includes an Applications shortcut and installation text; it does not yet have a custom Finder-positioned background layout.

The release is always a prerelease pending manual GUI validation. macOS CI does not prove first-launch dialogs, rendering, sound, widget installation, or App Group behavior. Perform the checklist in VALIDATION.md on a clean Mac before marking a release stable. Manual workflow dispatch builds artifacts without publishing a release; tag pushes publish a prerelease after successful gates.
