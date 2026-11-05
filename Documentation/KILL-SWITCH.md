# Internet kill switch: not implemented

The Security settings section explicitly reports that the requested system-wide internet kill switch is unavailable. It does not claim to block traffic and does not save an enabled flag. For actual leak protection use the kill switch supplied by a trusted VPN client.

A reliable implementation needs a properly provisioned and signed macOS network extension or equivalent supported system-level networking component, explicit system approval, and careful design of packet policy. The existing sandboxed menu-bar app has no such component or permission. A public-IP change is detected only after provider requests and two observations, so it cannot prevent traffic leakage before detection; periodic polling is not a VPN-disconnect kill switch.

Before enabling this feature, design and test on a real Mac: application and provider termination, VPN disconnect/reconnect, sleep/wake, network changes, IPv4/IPv6, DNS, local network and captive portal exceptions, startup before app launch, IPv6 leakage, user/system consent, uninstall, app updates, power failure, recovery controls, and a clear offline restore path that cannot strand the user. Obtain necessary Apple entitlements, developer signing, system-extension approval, and notarization. No firewall changes, privileged shell commands, or permanent network settings are performed by the current build.
