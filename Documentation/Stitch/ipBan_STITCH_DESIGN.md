# ipBan — Stitch UI/UX Design Brief

> **For Google Stitch:** Design a polished, implementation-ready UI/UX system and complete screen set for **ipBan**, a native **macOS 14+ menu bar public IP monitor**. The visual direction is **Apple-native, neo-glass, quiet, premium, functional**, with restrained futuristic accents. Create **design mockups, not screenshots of an existing application**.

## 1. Product definition

ipBan is a lightweight, privacy-conscious macOS utility for seeing public IPv4 and IPv6 addresses, connection metadata, approximate IP-based location, provider health, and confirmed IP-change history. The primary experience is a compact **menu bar popover**, with a separate **Settings** window and **small/medium/large macOS desktop widgets**.

**Important truth constraints**
- IP-based location is **approximate**, not GPS or precise physical location.
- An IPv4 or IPv6 value may be **unavailable**; never invent a missing address or location.
- “VPN/proxy evidence unknown” must not be represented as proof of safety, anonymity, or absence of a VPN.
- If provider data is stale, cached, offline, or errored, label it truthfully.
- Widgets show **last cached state**, **not real-time** network observations.
- A system-wide network **kill switch is not implemented**. It may appear only as an explicitly labeled **future concept**, never as an active or working control.
- No user account, location permission, telemetry opt-in, or background GPS is required. Provider requests disclose the user's public IP to the selected remote service.

## 2. Creative direction — “Liquid Clarity”

Create the visual sophistication of a first-party Apple macOS utility, **without copying an existing Apple app**. Favor practical information hierarchy over decorative sci-fi effects.

**Keywords:** neo-glass, frosted acrylic, liquid depth, layered translucent panels, macOS refinement, soft cyan / iris-violet illumination, subtle specular highlights, precise typography, airy but compact spacing, responsive states, native gestures, meticulous alignment.

**Must-have style**
- Dark and light appearances; both must look intentionally designed.
- Use **SF Pro** (system font fallback) for interface text, **SF Mono** for IPs, tokens, and diagnostics, **SF Symbols** for controls.
- Native vibrancy / translucent material: softly blurred background, hairline strokes, delicate inner highlights, subtle depth; **do not sacrifice legibility to transparency**.
- Mac-style popover anchored below a menu bar item, with rounded corners and refined shadow.
- Light gradient accents (cool cyan → blue → violet) used sparingly on primary focus, selected indicators, and graphic details, **not everywhere**.
- Colored status markers must also carry explicit readable labels and/or icons.
- Use subtle animation with Reduce Motion and Reduce Transparency fallbacks.
- No iPhone navigation bars, bottom tab bars, giant mobile cards, fake traffic maps, busy dashboards, cyberpunk neon, or unrealistic network traces.

## 3. Design tokens

### Surfaces and palette

| Token | Dark appearance | Light appearance | Usage |
|---|---|---|---|
| `canvas` | `#0D111B` | `#F4F7FB` | Conceptual canvas behind surfaces |
| `surface-base` | `#171E2B` | `#FFFFFF` | Main popover/settings surfaces, or equivalent native material |
| `surface-raised` | `#222D3D` | `#F6F9FC` | Cards, grouped settings |
| `surface-hover` | `#2B384B` | `#EAF0F7` | Hover/active surfaces |
| `text-primary` | `#F6F8FD` | `#152033` | Main text |
| `text-secondary` | `#A8B5C6` | `#516277` | Supporting text |
| `text-tertiary` | `#8694A8` | `#65768A` | Hints only; verify contrast |
| `stroke` | `#FFFFFF` at ~12–18% opacity | `#25344B` at ~10–14% opacity | Glass boundaries |
| `accent-cyan` | `#64D9F2` | `#087D9C` | Interactions / emphasis |
| `accent-violet` | `#A4A0FF` | `#6957C7` | Secondary accent |
| `success` | `#6BD6AA` | `#187A56` | Connected/healthy |
| `warning` | `#FFD18A` | `#965900` | Stale/cached/cooldown |
| `error` | `#FF999C` | `#B82E38` | Failed/offline |

**Color rules:** These are starting visual tokens, not a substitute for auditing rendered contrast. Use semantic system colors where possible. Meet **WCAG AA 4.5:1 for normal text**, **3:1 for large text and meaningful control boundaries**, across both themes and glass backdrops. Apply a stronger opaque scrim behind text when blur/contrast would otherwise fall short. Avoid relying on color alone.

### Typography

| Style | Size / weight | Usage |
|---|---|---|
| Popover title | 18px / semibold | “Overview”, screen title |
| IP hero | 23–26px / semibold, SF Mono | Main public IP, responsive to length |
| Section heading | 13px / semibold | Card / section title |
| Body | 13px / regular | Settings and data rows |
| Secondary | 12px / regular | Meta information |
| Caption | 11px / medium | Timestamps / status details |
| Button | 12–13px / medium | Toolbar and actions |

Support macOS user text scaling and localization; avoid truncating the meaning of a status. Selectable/copyable IP text must use tabular or monospaced digits; long IPv6 strings wrap deliberately or truncate visually with a full-value copy affordance.

### Geometry and spacing

- Base spacing unit: **4pt**; standard rhythm: **4 / 8 / 12 / 16 / 20 / 24 / 32pt**.
- Default popover: **~396pt wide × 540–620pt high** (adapt to screen and content, scroll interior only).
- Popover radius: **18–22pt**; glass content card: **14–16pt**; small control: **8–10pt**.
- Popover outer padding: **16pt**; cards inner padding: **12–16pt**; section gap: **12–16pt**; row height: **36–44pt**.
- Sidebar settings window: **~840 × 600pt** default, resizable, minimum usable **~720 × 520pt**.
- Hairline borders: **0.5–1pt**, light specular highlight on top-facing edges, gentle non-neon shadows.
- Minimum interactive target: aim for **28×28pt** in dense macOS controls; provide generous hit areas for primary actions and full keyboard access.
- Safe areas and bounds must work near display edges, notches and small laptop screens.

### Motion

- Hover/focus response: **100–150ms**.
- Card expansion / segment transition: **180–240ms** ease-out.
- Popover opening: subtle **160–220ms** opacity/translate; never dramatic bounce.
- Copy success: checkmark / “Copied” confirmation for **~1.5–2s**.
- Refresh progress: lightweight indeterminate indicator only while work is pending; avoid flashing or fake percentage progress.
- **Reduce Motion:** replace scale/slide effects with instant state changes or short fades. **Reduce Transparency:** replace blurred glass with semantic solid surfaces and visible boundaries.

## 4. Information architecture

**Menu bar trigger** → **Popover** with top persistent status header, five main tabs, a sixth **Designer** tab, and persistent bottom actions.

Popover tabs: `Overview`, `Network`, `Location`, `Providers`, `History`, `Designer`.

Header: app mark + title `ipBan`, connection status icon and text (`Connected`, `Offline`, `Checking…`, `Cached`), Settings gear.

Bottom action rail: `Refresh`, `Copy IP` (with family choice or preferred family), `Quit`. Keep visible while scrolling tab content.

Choose a compact macOS-appropriate **segmented top navigation or icon-with-label rail** that can fit six destinations without awkward wrapping. A narrow two-row icon navigation only if readability demands it. The **Designer** view is a utility/specification tab, not a marketing page.

## 5. Screen inventory and exact content

### A. Menu bar variations

Design a presentation sheet with realistic macOS menu bar snippets showing:
1. IPv4 address only: `203.0.113.42` (**fictional documentation IP**).
2. Flag + IPv4: `🇨🇦 203.0.113.42` (flag demo only; not geolocation inference).
3. Country + address: `CA · 203.0.113.42`.
4. Flag only.
5. Monochrome native symbol only.
6. ISP abbreviation + address.
7. Custom token template preview.
8. Shortened IPv6 `2001:db8:…:8a2e` (**documentation IPv6**).
9. Privacy mode `•••` or discreet shield icon.
10. Offline/unavailable and checking indicators.

Keep the symbol monochrome in the real menu bar; do not assume gradient icons are available there. The menu bar respects system appearance and avoids excess width. Truncation must retain an accessible tooltip or full value in popover.

### B. Overview — primary hero screen

A focused, elegant, compact dashboard:
- Header connection label and subtle status indicator.
- **Two independent address cards** labeled `IPv4` and `IPv6`, each with a monospaced address or `Unavailable` and its own copy button. Optional mini family glyphs (4/6), not huge flag iconography.
- Optional primary hero emphasis on preferred family, while still displaying the other family plainly.
- Approximate location row: country flag + `Toronto, Canada` (example only) + `Approximate · IP-based`.
- Network organization / ISP and source provider in clear rows.
- `Updated just now` / absolute timestamp on hover or details; use honest `Last successful update` language.
- Compact `Cached data · last checked …` warning when applicable.
- Bottom Refresh / Copy IP / Quit.
- Show unobtrusive copy checkmark and `Copied IPv4` / `Copied IPv6` toast that can be announced by VoiceOver.

### C. Network

Structured diagnostic rows, with clear labeling:
- Public IPv4, public IPv6 (independent, copyable).
- Active interface type: e.g. `Wi‑Fi` / `Ethernet` / `Unknown`.
- ISP, organization, ASN (e.g. `AS64500` demo/test ASN).
- VPN/proxy **evidence status**: `Detected`, `Not reported`, or `Unknown`, with explanation that provider evidence is limited and not a guarantee.
- Use small nested rows instead of a full networking console. Long organizations and identifiers must reflow.

### D. Location

- Header `Approximate location` and explanatory text: `Based on your public IP. Not your precise location.`
- Country + flag, region, city, postal code, time zone; coordinates **only when provided** and labeled approximate.
- Optional **abstract soft globe/contour graphic** as purely decorative, not a fabricated map pin marking exact whereabouts.
- Fields missing from provider responses render `Not available` rather than a fake estimate.
- A quiet privacy explanation, and no GPS permission prompt.

### E. Providers

Design list and detail states for **eight provider adapters**, use neutral provider labels (`Provider 1–8`) when actual names aren't supplied; do not invent brand names.

Each provider row/card includes:
- Name, enabled status, priority order.
- Capability chips: `IP discovery`, `Location`, `IPv6` **only when supported**.
- Success/failure counts, last response latency, last error, cooldown, health status.
- Selection: `Automatic fallback` versus `Manual provider`.
- Show `Retry-After` / cooldown state, unavailable results, and non-blocking error messages.
- An informative `Provider health is based on recent requests` caption.
- For compact popover, prefer scan-friendly summary rows; deeper controls reside in Settings → Providers.

### F. History

- Search control and chronological change list, newest first.
- Each entry has timestamp, IP family (`IPv4` or `IPv6`), `Previous → Current` monospaced values, and observed reason (`Network changed`, `Scheduled check`, `Wake`, etc.) when known.
- Small explanation `Changes are recorded after two consecutive matching observations.`
- Distinguish IPv4 and IPv6 events; no single blended IP-change history state.
- Empty state: simple timeline glyph, `No confirmed changes yet`, and factual explanatory text.
- Search empty results, retention expiry, and export entry point.
- Use fictional reserved addresses in examples: IPv4 `198.51.100.12` → `203.0.113.42`; IPv6 `2001:db8::1` → `2001:db8::2`.

### G. Designer

- A read-only, copyable panel headed `Design specification`.
- Structured design tokens and concise UI behavior specification; `Copy specification` action.
- Banner `Contains no personal IP addresses, location details, or credentials.`
- Use placeholder/demo values only. Do not accidentally display live personal information.

## 6. Mandatory state variants

Create separate artboards or component state examples for:

| State | Required UI behavior |
|---|---|
| First run | Friendly product intro, overview of what is checked and provider data disclosure; explicit user-controlled choices |
| Online | Healthy connected status, distinct IPv4 and IPv6 values if available |
| Loading / refreshing | Skeletons for **not-yet-known** values or inline progress; don't blank valid cached data unnecessarily |
| Offline | `Offline` badge, previously cached values shown **only** if present, clear last successful timestamp |
| Provider error | Contextual explanation, retry control, automatic fallback messaging if active |
| IPv4 unavailable | `IPv4 unavailable` in its own card; IPv6 remains independent |
| IPv6 unavailable | `IPv6 unavailable` in its own card; IPv4 remains independent |
| Both unavailable | Graceful empty overview, `Try again` action, no invented content |
| Cached / stale | Amber `Cached`/`Stale` label with update age and reason if known |
| Copy success | Small checkmark and spoken message identifying copied family |
| Privacy mode | Address/organization/location visually hidden, copy gated as appropriate, widget sensitive data removed |
| Empty history | Clear zero state, no mock history records presented as real |
| Provider cooldown | Disabled/limited action plus countdown or `Available later`, if known |
| Permission denied | Provide route to macOS settings, never silently change permissions |
| Reduced transparency | Solid card/background variant without blur |
| Keyboard focus | Strong visible focus rings on every interactive element |

Never mix real connected data with fake illustrative records inside the same “live” artboard. Mark demo content `Sample data` where appropriate.

## 7. Standalone Settings window

Create a **macOS Settings window**, not a mobile settings page: sidebar navigation with SF Symbols, search only if useful, right-hand grouped panels, native switches, pop-up menus, steppers/sliders, and clear descriptions. Create a **separate detailed artboard for every section**.

### General
- Launch at login (uses system user-controlled login item behavior).
- Appearance: `System`, `Light`, `Dark`.
- Refresh / polling interval selection.
- IPv6 discovery toggle (default enabled) and clear caveats.
- Network-change checks / wake behavior description, if shown.

### Menu Bar
- Live visual format preview (using safe documentation IPs).
- Format: address, flag + address, country + address, flag only, monochrome icon, ISP abbreviation, custom tokens.
- Preferred family: `Auto`, `IPv4`, `IPv6`.
- Compact / shortened IPv6 appearance.
- Custom token input with syntax help, reset, and validation error examples.

### Providers
- Automatic fallback versus manual provider selection.
- Enable/disable eight services and reorder their priority with accessible controls.
- Timeout and diagnostics; provider test and reset actions.
- Optional IPinfo token field with masked entry and `Stored in Keychain` description; never expose an actual token.
- A privacy note: remote provider calls disclose public IP.

### Notifications
- Current OS authorization status; `Enable notifications` requests access **only when user opts in**.
- IP-change and connection-change notification toggles.
- Quiet hours time controls.
- Denied permission recovery: `Open System Settings` and helpful explanation.

### Sounds
- Master opt-in switch.
- Six synthesized original sound selections using neutral labels (`Tone 1–6`) unless actual names are provided.
- Volume slider and preview button. Clear disabled state when sounds are off.

### History
- Retention duration.
- Export `CSV` / `JSON` with save-dialog expectation.
- `Clear history` with destructive confirmation and non-scary, precise copy.

### Privacy
- Hide sensitive information in popover/menu bar/widget.
- Clarify whether copying is blocked or disabled while private (follow product behavior; show as a design choice if undetermined).
- Delete cached results / clear history with separate confirmations.
- No account, telemetry or location permission requirement.

### Security
- Informative, **disabled** `Network kill switch` row explicitly labeled `Not available in this version`.
- Optional visually separated **Future concept — not implemented** approval/recovery design sheet, but never as a usable setting.

### About
- ipBan logo, app name, version placeholder, macOS support.
- Repository and license links as placeholders pending actual URLs.
- Brief privacy-first positioning, acknowledgements if provided.

## 8. First-run onboarding

Design 3 compact macOS onboarding steps (either one window with step indicators or a thoughtful short flow):

1. **Welcome to ipBan** — what public IP monitoring does, what it does not do; showcase menu bar entry.
2. **Choose your experience** — preferred IP family / menu bar style, polling preference, optional IPv6 discovery; clear sensible defaults.
3. **Your privacy and notifications** — explain public IP exposure to selected providers, notification permission only when user explicitly enables it, and optional launch at login.

Use `Continue`, `Back`, `Finish`, `Not now` where appropriate. No forced sign-in. Distinguish informational disclosures from permission prompts. If permission rejected, the app remains fully usable for core checking.

## 9. macOS desktop widgets

Design **three distinct native WidgetKit layouts**, for both light and dark surfaces, with privacy variants and stale states:

- **Small:** current preferred-family cached IP or privacy placeholder, connection marker, update age. Avoid cramming ISP + location into this size.
- **Medium:** separate IPv4 and IPv6 lines, current connection state, last checked, short country/provider if there is room.
- **Large:** both IP addresses, approximate location, ISP/organization, source provider, last successful update, clear cached/stale label.

Include `Updated 12 min ago` example and a tiny honest caption: `Updates when macOS schedules a refresh`. Widget is **not live** and is privacy-sanitized. Use simulated sample IPs, not real private values.

## 10. Notifications and transient feedback

Create macOS-native notification concept examples for:
- Confirmed IPv4 change (previous → current abbreviated if necessary).
- Confirmed IPv6 change.
- Connection offline / back online, only if user enabled the respective notification.
- Copy success inline toast/popover hint.
- Refresh error banner with safe retry affordance.

Respect quiet hours and denied permission. Don't show notification banners as guaranteed to appear; macOS may suppress them by system policy.

## 11. Future-only network kill switch approval/recovery concepts

This feature **does not exist in ipBan**. Only deliver clearly separated, watermark-like **`Future concept — unavailable in current build`** designs:
- Informational explanation and potential system approval flow.
- Authorization pending / declined / revoked and recovery guidance.
- Status surfaces that **never claim network protection is active**.
- No mock control that appears operable in the shipped Settings screen.

## 12. Accessibility and localization

- VoiceOver labels every control and announces full IPv4/IPv6 values and update status.
- Keyboard navigation through tabs, controls, search, lists, popover actions and dialogs; strong focus indicator.
- Text must remain readable against variable desktop wallpapers and translucent surfaces.
- Status expressed through text + icon as well as color.
- Reduce Motion / Reduce Transparency / Increase Contrast compatibility.
- Long IPv6 addresses, long non-English region/organization names, right-to-left layouts, and macOS text-size settings should not cause overlap.
- Minimum contrast: normal text **4.5:1**, large text and meaningful graphic/UI boundaries **3:1**.
- Flag icons are supplementary and not the sole location or country identifier.

## 13. Deliverables / artboard checklist

**Design all of the following, not just a single dashboard:**

1. Overall visual direction / materials / tokens board.
2. Menu bar format variants (at least 10).
3. Overview popover: dark, light, connected.
4. Network, Location, Providers, History, Designer popover tabs.
5. Loading, offline, provider error, unavailable IPv4, unavailable IPv6, both unavailable, cached/stale, privacy, empty history, copy confirmation, and reduced-transparency variants.
6. Standalone Settings overview + all nine sections: General, Menu Bar, Providers, Notifications, Sounds, History, Privacy, Security, About.
7. Onboarding: 3 screens.
8. WidgetKit: small, medium, large; light/dark/privacy where appropriate.
9. Native notifications, copy feedback, error banners, permission denied recovery.
10. Future-only kill switch approval/recovery concept sheet, visibly marked **not implemented**.
11. Components: header, tab control, IP card, info row, provider health row, family badge, status pill, copy button, action rail, toasts, skeleton, empty state, switches, dropdowns, search field, focus state.
12. Annotated design specs for spacing, type, colors, hover/pressed/disabled/focus states, motion timings, accessibility and responsive constraints.

### Stitch output expectations

- Deliver coherent **high-fidelity desktop macOS artboards** and a reusable component system.
- Prioritize **Overview popover + Settings** quality and the genuine menu bar context.
- Include **light and dark**, at minimum for hero screens.
- Use clear section/frame names: `Popover / Overview / Dark / Online`, `Settings / Providers / Light`, etc.
- Design should be realistic to implement using **SwiftUI, AppKit where needed, WidgetKit, SF Symbols, and native macOS controls**.
- Glass effects must have a straightforward native-material fallback; not a custom GPU-only shader requirement.
- Use only fictional **documentation-range** IP examples (`203.0.113.42`, `198.51.100.12`, `2001:db8::1`), and label them sample/demo values.
- Avoid filling unknown real provider capabilities or technical details with fabricated information.
- Show a cohesive UI across the popover, Settings and widgets, rather than independent art directions.

## 14. Final quality bar

The finished product should feel like **a small, beautiful, trustworthy macOS companion**: immediate IP legibility, confidently restrained frosted layers, purposeful cyan/violet accents, exact alignment, low cognitive load, and truthful network-status semantics. It should look premium in a screenshot **and remain usable every day** as a compact utility.
