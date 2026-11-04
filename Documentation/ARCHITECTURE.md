# Architecture

`macOS/Core` is the portable Swift 6 `PrismCore` module. It has no UI or Apple-only imports except conditional POSIX address parsing. `IPProvider` adapters normalize provider-specific responses into optional intelligence fields. `HTTPTransport` permits deterministic transport mocks. `ProviderManager` is an actor that owns cache, in-flight tasks, cooldowns, budgets, and health.

`ChangeDetector` maintains separate IPv4/IPv6 accepted observations and requires two consecutive observations of a new value. Switching address families is not an IP change. Confirmation currently occurs on the next scheduled lookup, not an immediate extra request.

`HistoryStore` uses atomic JSON files with retention. `NotificationPolicy` implements quiet hours and cooldown logic without macOS dependencies. `PrismShared` tests the widget cache serialization.

`macOS/Sources` contains the main-actor UI model, menu bar application, tabbed panel, settings, and platform services. URLSession handles asynchronous networking. NWPathMonitor events are debounced. Scheduling uses cancellable tasks; sleep cancels scheduled work, and wake schedules another lookup. No system daemon is installed.

The widget is a separate WidgetKit extension reading App Group state. Privacy mode strips sensitive fields from shared snapshots. No API calls run inside the widget. Widget timing is controlled by macOS.

`Scripts/generate-project.py` deterministically writes the committed Xcode project, Info.plists, entitlements, and shared scheme. The app links a local Swift package; the extension compiles only widget/shared sources. There are no external runtime dependencies.
