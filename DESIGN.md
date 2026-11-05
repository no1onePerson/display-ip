# IpBan — native design system

IpBan is a compact macOS menu bar utility. The mark is a network symbol. Original geometric artwork is generated into the macOS icon sizes; no Apple brand assets are used.

Use real SwiftUI system materials with semantic colors. A regular-material shell contains thin-material cards; Reduce Transparency substitutes an opaque system background. Addresses use the system monospaced face. Data has a clear hierarchy: connection address, location, provider, timestamp. Long addresses wrap rather than overflow.

A 396-point popover holds Overview, Network, Location, Providers, History, and Designer. Settings is a separate window, about 840 by 600 points, with a sidebar and grouped native controls. Permission explanations precede optional system prompts. Failures preserve cached data and show an explicit stale or offline label. Unknown fields say Unavailable. VPN or proxy status is unknown unless a provider reports evidence.

Motion is a short ease-in-out section transition, disabled with Reduce Motion. A native progress indicator shows active work. Copy confirmation is text and icon feedback. Sounds are original, short synthesized tones with attack/decay envelopes, explicit opt-in, volume, cooldown, and quiet hours.

Widgets prioritize a cached address and timestamp, with more details in medium/large sizes. Privacy mode removes sensitive shared values. Native monochrome menu bar symbols follow system tint.

Before a stable release, inspect actual rendering in light/dark, contrast modes, VoiceOver, Reduce Motion, Reduce Transparency, long IPv6, empty/error/loading states, and keyboard navigation. No pixel-perfect or accessibility conformance claim is made without those native checks.

## Stitch: Liquid Clarity

The 2026 Stitch references live in [Documentation/Stitch](Documentation/Stitch/ipBan_STITCH_DESIGN.md). The native implementation uses a compact material popover, separate public IPv4/IPv6 cards, cyan/violet protocol accents, a legible status pill, a settings sidebar with native controls, three-step optional onboarding, and family-specific cached widgets. Light appearance uses a darker cyan, and Reduce Motion and Reduce Transparency remain supported. The Stitch images and HTML contain illustrative data and must not be represented as actual runtime screenshots or measurements.
