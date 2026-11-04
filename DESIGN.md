# IP Prism — native design system

IP Prism is a compact, restrained macOS utility. The prism mark combines refracting cyan/violet planes with a globe arc and network point. Original geometric artwork is generated into all macOS icon sizes; no Apple brand assets are used.

Use real SwiftUI system materials with semantic colors. A regular-material shell contains an ultra-thin card; Reduce Transparency substitutes an opaque system background. Typography uses the system face with rounded address numerals. Data has a clear hierarchy: connection address, location, provider, timestamp. Long addresses wrap rather than overflow.

A 490-point panel separates Overview, Network, Location, Providers, and History. Settings use a sidebar and grouped native controls. Permission explanations precede optional system prompts. Failures preserve cached data and show an explicit stale/offline message. Unknown fields say Unavailable; uncertain VPN/proxy status is never presented as a fact.

Motion is a short ease-in-out section transition, disabled with Reduce Motion. A native progress indicator shows active work. Copy confirmation is text and icon feedback. Sounds are original, short synthesized tones with attack/decay envelopes, explicit opt-in, volume, cooldown, and quiet hours.

Widgets prioritize a cached address and timestamp, with more details in medium/large sizes. Privacy mode removes sensitive shared values. Native monochrome menu bar symbols follow system tint.

Before a stable release, inspect actual rendering in light/dark, contrast modes, VoiceOver, Reduce Motion, Reduce Transparency, long IPv6, empty/error/loading states, and keyboard navigation. No pixel-perfect or accessibility conformance claim is made without those native checks.
