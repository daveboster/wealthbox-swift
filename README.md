# Wealthbox Swift

`wealthbox-swift` is a Swift package for read-only Wealthbox API access from
Swift apps and terminal workflows.

The package currently exposes a Foundation-only library product named
`Wealthbox` and a command-line executable named `wealthbox`. SwiftUI and
SwiftData views copied into the local `import/` staging folder are intentionally
not part of the first public package surface.

## Package

Use Swift Package Manager:

```swift
.package(url: "https://github.com/daveboster/wealthbox-swift.git", exact: "0.1.0-alpha.1")
```

The library product is `Wealthbox`.

```swift
import Wealthbox

let client = WealthboxApiClient(accessToken: "<access-token>")
let workspace = try client.getCurrentUser()
let contacts: WBContacts = try client.get(.contacts)
let event = try client.getEvent(id: 123)
```

## CLI

Build and run the included terminal command with SwiftPM:

```bash
swift run wealthbox --help
```

The CLI reads an access token from `--token` or `WEALTHBOX_ACCESS_TOKEN`.
`--base-url` or `WEALTHBOX_BASE_URL` can override the default
`https://api.crmworkspace.com` endpoint.

To avoid putting tokens in shell history, store the token in the macOS Keychain
and source the checked-in helper:

```bash
security add-generic-password \
  -U \
  -s wealthbox-swift \
  -a WEALTHBOX_ACCESS_TOKEN \
  -w '<access-token>'

source bin/load-wealthbox-token
```

`bin/load-wealthbox-token` exports `WEALTHBOX_ACCESS_TOKEN` into the current
shell. If the token is already set, it leaves it alone. If the Keychain item is
missing, it prompts silently. You can override the Keychain lookup with
`WEALTHBOX_KEYCHAIN_SERVICE` and `WEALTHBOX_ACCESS_TOKEN_ACCOUNT`.

```bash
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox me --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox contacts --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox contact 48828625 --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox contact-custom-fields --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox events --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox events --week 0 --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event 77622943 --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event-categories --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event-custom-fields --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event-update-category 77622943 --from-category-id 2 --to-category-id 1 --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event-update-category 77622943 --from-category-name "Review" --to-category-name "Client Meeting" --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox event-update-status 77622943 --from-status confirmed --to-status completed --pretty
WEALTHBOX_ACCESS_TOKEN=... swift run wealthbox events --include-categories --pretty
```

The CLI is read-only except for explicit update commands.

The `events --week <offset>` option filters fetched events by the event
`starts_at` value. Weeks start on Sunday. Use `0` for the current week, `-1` for
the week before, and `1` for the week after.

Use `event-categories` to fetch the event category id/name values from
Wealthbox's customizable categories endpoint. Event records expose their
category id as `event_category`.

Use `event-custom-fields` to fetch the custom field definitions and available
options for events from `/v1/categories/custom_fields?document_type=Event`.

Use `contact-custom-fields` to fetch the custom field definitions and available
options for contacts from `/v1/categories/custom_fields?document_type=Contact`.

Use `events --include-categories` to fetch event categories before fetching
events and append the matching category object under `category` in each event.
The original `event_category` id remains unchanged.

Use `event-update-category` to update an event's `event_category` only after
checking the event currently has the expected category. Pass exactly one
`--from-category-id` or `--from-category-name`, and exactly one
`--to-category-id` or `--to-category-name`. If the fetched event category does
not match the `from` selector, no update is sent.

Use `event-update-status` to update an event's `state` only after checking the
event currently has the expected status. Valid statuses are `unconfirmed`,
`confirmed`, `tentative`, `completed`, and `cancelled`. If the fetched event
state does not match `--from-status`, no update is sent.

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
