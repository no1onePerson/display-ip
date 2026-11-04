# Contributing

Use Swift 6 and Xcode 16.4+. Run `swift test --package-path macOS`, regenerate the project after source membership changes, and build app/widget targets before submitting a PR. Provider tests must use deterministic fixtures and reserved documentation addresses, not live user data. Do not add dependencies or provider requests without documenting their privacy and quota impact.

Describe behavior, test results, and any macOS checks you could not run. Include actual screenshots for UI changes only after running the app. Preserve optional-field semantics, strict concurrency, HTTPS, and last-known-good state. Never commit API keys, private addresses from logs, signing material, or credentials.
