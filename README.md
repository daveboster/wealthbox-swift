# Wealthbox Swift

`wealthbox-swift` is a Swift package for Wealthbox API access from Swift apps
and terminal workflows. Reads cover the current user/workspace, contacts, and
events; the library also supports creating notes (`POST /v1/notes`).

The package exposes a Foundation-only library product named `Wealthbox` and a
command-line executable named `wealthbox`. It builds for macOS, iOS, iPadOS, and
Mac Catalyst. SwiftUI and SwiftData views copied into the local `import/` staging
folder are intentionally not part of the first public package surface.

## Package

Use Swift Package Manager:

```swift
.package(url: "https://github.com/daveboster/wealthbox-swift.git", exact: "0.1.0-alpha.2")
```

The library product is `Wealthbox`.

```swift
import Wealthbox

let client = WealthboxApiClient(accessToken: "<access-token>")

// Reads
let workspace = try client.getCurrentUser()
let contacts: WBContacts = try client.searchContacts(name: "Anderson")
let event = try client.getEvent(id: 123)

// Write: create a note linked to a contact
let note = try client.createNote(content: "Reviewed the plan.", contactId: 48828625)

// Typed errors for retry flows
do {
    _ = try client.getCurrentUser()
} catch let error as WealthboxError where error.isRetriable {
    // retry, honoring error.retryAfterSeconds when present
}
```

## CLI

Build and run the included terminal command with SwiftPM:

```bash
swift run wealthbox --help
```

The CLI reads an access token from `--token` or `WEALTHBOX_ACCESS_TOKEN`.
`--base-url` or `WEALTHBOX_BASE_URL` can override the default
`https://api.crmworkspace.com` endpoint.

```bash
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox me --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox contacts --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox contact 48828625 --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox events --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event 77622943 --pretty
```

The CLI is read-only in the first release.

## Validation

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift test
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift build
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift run wealthbox --help
```

Live Wealthbox API calls are not part of the default test suite. They require
`WEALTHBOX_ACCESS_TOKEN` and should be run manually.

## Versioning

`wealthbox-swift` uses semantic versioning. While the package is below 1.0,
alpha prereleases such as `v0.1.0-alpha.1` are expected while the public API
shape stabilizes. Patch releases should remain source-compatible within the
same minor version. Minor releases may include source-breaking API or package
boundary changes before 1.0.

Package release pull requests must update [CHANGELOG.md](CHANGELOG.md).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
before broad API, endpoint, CLI, or package-boundary changes.

## Security

Do not post access tokens, API responses with private client data, or
security-sensitive reports in public issues. See [SECURITY.md](SECURITY.md).

## License

`wealthbox-swift` is available under the MIT License. See [LICENSE](LICENSE).
