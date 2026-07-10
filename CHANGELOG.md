# Changelog

All notable changes to `wealthbox-swift` are documented here.

This project uses semantic versioning. While the package is below 1.0, alpha
prereleases may include source-breaking API changes as the public Wealthbox
client surface stabilizes. Patch releases should remain source-compatible
within the same minor version.

## 0.1.0-alpha.2 - 2026-07-10

- Added iOS and Mac Catalyst platform support so the `Wealthbox` library can be
  linked into iOS/iPadOS/Mac Catalyst apps alongside macOS.
- Added `WBNote` and `WBNoteLink` models and a `POST /v1/notes` write path —
  `createNote(content:linkedTo:visibleTo:)` plus a single-contact convenience —
  the first write-capable endpoint on `WealthboxApiClient`.
- Added `searchContacts(name:email:type:active:page:perPage:)` for
  `GET /v1/contacts` using Wealthbox's documented query parameters, and a
  `getContact(id:)` convenience.
- Expanded `WealthboxError` with `.rateLimited(retryAfter:)` (HTTP 429) and a
  dedicated `.network(message:)` case for transport failures. Source-breaking:
  transport errors previously surfaced as `.serverError(code: -1, message:)`
  and now surface as `.network(message:)`.
- Added `WealthboxError.isRetriable` and `WealthboxError.retryAfterSeconds`
  helpers for user-facing retry flows.
- Added Swift Testing coverage for contact-search query construction, note
  creation (request body and response decoding), 429 rate-limit handling, and
  error classification.

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
