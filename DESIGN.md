# Display IP — native Apple-inspired design

## Direction

A quiet, glassy utility that belongs in the macOS menu bar. Native SwiftUI materials let the desktop subtly show through. Use semantic foreground colors, rounded typography, SF Symbols, generous spacing, and a clear hierarchy: public address, location, network details, then actions. No imitation title bars or Apple branding.

## Surfaces and motion

The menu bar opens a compact 390-point panel with a regular-material backdrop and an ultra-thin-material inner card. A faint border gives depth. Animate address changes with a short 250 ms transition; respect Reduce Motion. Keep loading visible and retain the timestamped previous result on failure. Never show invented location or network details.

## Controls

Native settings use grouped sections for menu bar formatting, provider preference, refresh interval, and system integration. Permission prompts occur when the relevant toggle is enabled. Expose system errors. A hidden menu bar label falls back to a network symbol so the app stays reachable. Widgets show the last successful lookup and its timestamp.

## Release quality gate

Verify contrast, keyboard navigation, VoiceOver, Reduce Transparency, Reduce Motion, dark/light appearance, long IPv6 addresses, permission denial, App Group sharing, and signed installation on macOS before calling a release stable. The initial release is a preview until these checks and notarization are complete.
