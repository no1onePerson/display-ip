# Provider contracts and verification

All runtime requests use HTTPS. Unknown fields stay absent. Provider answers describe the endpoint observed by that provider; network route changes and dual-stack routing can produce different answers. Geolocation differences are not transport failures.

| Adapter | Endpoint | Capabilities | Documentation |
|---|---|---|---|
| IPWho.is | https://ipwho.is/ | Discovery, location, network | https://ipwhois.io/documentation |
| IPinfo | https://ipinfo.io/json | Discovery, optional location/network | https://ipinfo.io/developers |
| ipapi.co | https://ipapi.co/json/ | Discovery, location, network | https://ipapi.co/api/ |
| GeoJS | https://get.geojs.io/v1/ip/geo.json | Discovery, location, network | https://www.geojs.io/docs/v1/endpoints/geo/ |
| FreeIPAPI | https://free.freeipapi.com/api/json | Discovery, location | https://freeipapi.com/docs |
| ipify | https://api.ipify.org?format=json | IPv4 discovery | https://www.ipify.org/ |
| icanhazip | https://icanhazip.com/ | Plain-text discovery | https://icanhazip.com/ |
| Cloudflare Trace | https://www.cloudflare.com/cdn-cgi/trace | Discovery, country only | https://developers.cloudflare.com/fundamentals/reference/cdn-cgi-endpoint/ |

Optional IPv6 discovery uses https://api6.ipify.org?format=json and https://ipv6.icanhazip.com/. Cloudflare trace is a diagnostic endpoint, not a guaranteed geolocation API. No VPN/proxy classification is inferred from trace, ISP, country, or ASN.

## Verification status

On 2026-11-04, requests to provider/documentation sites were blocked by the cloud proxy with HTTP 403. Consequently current authentication requirements, free tiers, redistribution rights, response schemas, and usage terms have **not** been live-verified. Fixture tests validate parser behavior against the expected contracts, not upstream availability. Do not describe these integrations as verified production services until the documented checks below are done.

Before stable release, review each linked provider's current terms, permitted application use, attribution, privacy policy, free quotas, and API contract. Disable any provider whose terms do not permit the intended distribution. No additional providers were added beyond those explicitly requested.

## Request policy

Automatic mode stops on the first valid response and does not query all providers per refresh. Manual mode uses only the selected provider. Location from one address is never attached to a different provider's address. This initial implementation does not independently enrich discovery-only answers.

Minimum intervals: 120 seconds for ipapi.co, 60 seconds for other adapters. Local 24-hour budgets are conservatively capped at 500 and 1,000 requests respectively; these are application safeguards, **not claims about current provider quotas**. Budget and cooldown state is persisted locally across relaunches when disk storage is available. HTTP 429 Retry-After overrides local retry timing; failures back off with jitter and three consecutive failures open a cooldown circuit. Reset Statistics preserves the active request budget/cooldown. IPv6 discovery has a separate scheduler; account for its additional requests when setting quotas.

An optional IPinfo token is stored in macOS Keychain and sent only as an Authorization header to ipinfo.io. Basic fallback does not require a token. Never place tokens in issue reports, exported diagnostics, or source control.
