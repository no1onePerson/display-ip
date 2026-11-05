# Changelog

## 0.4.0 development preview

The app is IpBan. The menu bar gear waits until the panel closes, then opens a retained settings window and brings it forward. Closing that window returns to the menu bar on a real session. The release build keeps that close callback off the main-actor executor, because Xcode 16.4 traps when AppKit calls an isolated method. The runner also traps if the smoke test changes activation policy, so that check only activates and orders the window forward. Native CI builds and analyzes arm64 and x86_64 together so the core module exists for both slices. The Xcode project, widget, and URL scheme use the IpBan name; the previous URL scheme still opens the app. The system-wide kill switch remains unavailable. This preview is ad-hoc signed, not notarized.

## 0.3.0 development preview

Rebuilt the native application as IP Prism. Added the Swift 6 portable core, eight provider adapters, request scheduling and failure controls, family-aware confirmation, local history/export, privacy and quiet-hour controls, original synthesized sounds, provider settings, widget sizes, generated icons and committed Xcode project, and signed/unsigned release paths. Sixteen portable tests pass. Native build, UI, provider terms, and signed release verification remain pending.

## 0.2.0 preview

Initial Display IP native menu bar application and widget source.
