# Contributing

Thanks for helping improve `wealthbox-swift`.

## Scope

The first package surface is a reusable Foundation-only Wealthbox client and
read-only CLI. Keep app-specific UI, SwiftData persistence, navigation,
credentials, and host-app configuration out of the core package unless the
package boundary is intentionally expanded.

Before broad API, endpoint, CLI, persistence, or SwiftUI changes, open an issue
describing the consuming-project need and why the behavior belongs in this
package instead of a host app.

## Development

Use the full Xcode toolchain when working locally:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift test
```

For a broader smoke check:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift build
CLANG_MODULE_CACHE_PATH=/private/tmp/clang-module-cache swift run wealthbox --help
```

## Pull Requests

- Keep pull requests focused and reviewable.
- Add or update tests for behavior changes.
- Update `README.md` or `CHANGELOG.md` when changing public APIs, setup,
  commands, or package boundaries.
- Do not commit access tokens, `.tokenStub`, `.env` files, or API responses
  containing private Wealthbox data.
- Keep live API calls opt-in and out of the default test suite.

## Release Notes

Release notes should be written for package consumers. Include user-facing API,
behavior, setup, validation, command, or dependency changes. CI-only or
documentation-only changes can be described as maintenance.

## Pre-1.0 Versioning

Use alpha tags such as `v0.1.0-alpha.1` while the public API shape stabilizes.

Use patch tags such as `v0.1.1` for source-compatible fixes within the current
minor version:

- bug fixes
- documentation or CI maintenance
- dependency updates that do not change host app integration
- additive APIs that do not change existing consumer expectations

Use minor tags such as `v0.2.0` when the package boundary changes:

- source-breaking public API changes
- endpoint model changes requiring host-app updates
- CLI command changes that require script updates
- larger feature additions that need a new stabilization window

Package release pull requests must update `CHANGELOG.md`. Mark a pull request
as a package release by using a title that starts with `release:` or by applying
the `release` label.
