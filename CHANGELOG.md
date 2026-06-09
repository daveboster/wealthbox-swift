# Changelog

All notable changes to `wealthbox-swift` are documented here.

This project uses semantic versioning. While the package is below 1.0, alpha
prereleases may include source-breaking API changes as the public Wealthbox
client surface stabilizes. Patch releases should remain source-compatible
within the same minor version.

## 0.1.0-alpha.1 - 2026-06-09

- Initial public alpha Swift package release.
- Added the Foundation-only `Wealthbox` library product.
- Added read-only models for current user/workspace, contacts, and events.
- Added `WealthboxApiClient` with configurable base URL, access-token header,
  and mapped HTTP/transport errors.
- Added the `wealthbox` command-line executable with `me`, `contacts`,
  `contact`, `events`, and `event` commands.
- Added Swift Testing coverage for model decoding and API client request/error
  behavior.
- Added CI, release PR changelog checks, and release readiness script.
- Published under the MIT License.
