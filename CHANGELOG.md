# Changelog

All notable changes to `wealthbox-swift` are documented here.

This project uses semantic versioning. While the package is below 1.0, alpha
prereleases may include source-breaking API changes as the public Wealthbox
client surface stabilizes. Patch releases should remain source-compatible
within the same minor version.

## Unreleased

- Added the tier-2 QA-workspace integration suite
  (`WealthboxQAIntegrationTests`): live contract tests that run only
  when `WEALTHBOX_QA_ACCESS_TOKEN` is supplied at call time via
  `bin/wb-qa-run` (Keychain-backed), and are skipped entirely — zero
  network calls — in `swift test` and CI. Covers the open contract
  questions: `/v1/me` guard fields, note tags, update-vs-append note
  semantics, the (absent) tags field on tasks, task delete + not-found error
  shape, the unrouted notes delete, throttling vs the one-note-plus-N-tasks
  save fan-out, and error shapes for mock foldback.
- Added the `WealthboxQA` library product — the shared QA-run
  harness for package tier-2 tests and consuming-app tier-3 smoke tests:
  `QAWorkspaceGuard` (aborts unless `/v1/me` proves the credential
  targets the QA workspace; strict sole-membership by default, with
  the multi-workspace credential shape refused),
  `QARunEnvironment` (`WEALTHBOX_QA_*` call-time configuration),
  `QARunID`/`QAArtifactMarker` (the `wb-qa-test` tagging
  convention: note tags plus body/description run markers), and
  `QASweeper` (marker-strict cleanup planning/execution with no
  contact operations in its reach).
- Added the `wealthbox-qa` executable with read-only `verify` and
  dry-run-by-default `sweep` subcommands (tasks are hard-deleted; notes are
  tombstoned in place because Wealthbox exposes no notes delete endpoint;
  seeded households are structurally untouchable).
- Added `bin/wb-qa-run`, the Keychain wrapper that exports the
  QA key (service `wealthbox-swift-qa`) into a single command's
  environment at call time.
- Added note read/update support on `WealthboxApiClient`: `getNote(id:)`,
  `getNotes(filters:)` with `WBNoteListFilters` and the `WBNotes`
  `status_updates` envelope, `updateNote(id:content:linkedTo:visibleTo:tags:)`
  (`PUT /v1/notes/{id}`), and a documented `tags` parameter on
  `createNote`.
- Added `deleteTask(id:)` (`DELETE /v1/tasks/{id}`, decoding the returned
  task body) and an optional documented `status` field on `User`.
- Added `docs/QA_WORKSPACE_TESTING.md`: Keychain service/account
  naming, run instructions, identity-guard rules, tenant-hygiene
  conventions, and the manual (never scripted) Wealthbox UI seeding steps
  for fictional sample households.
- Added `WBTask`, `WBTasks`, `WBSubtask`, and `WBTaskLink` models and a task
  read/write path on `WealthboxApiClient`: `getTask(id:)`, `getTasks(filters:)`,
  and `createTask(...)` (`GET`/`POST /v1/tasks`) plus a single-contact
  `createTask` convenience. Create supports the documented fields — `name`,
  `due_date`, `assigned_to`/`assigned_to_team` (mutually exclusive), `linked_to`
  (Contact/Project/Opportunity; households link as contacts), `category`,
  `priority`, `visible_to`, `description`, `custom_fields`, and `subtasks`.
- Added `WBTaskListFilters` for the documented `GET /v1/tasks` query parameters
  (`resource_id`, `resource_type`, `assigned_to`, `assigned_to_team`,
  `created_by`, `completed`, `task_type`, `updated_since`, `updated_before`,
  `page`, `per_page`). Polling this list — or `getTask(id:)` — is the only
  status-readback path; Wealthbox exposes no task webhooks (`GET /v1/webhooks`
  returns 404).
- Added `WBCustomFieldRequest` (the `{ id, value }` write shape for custom
  fields) and `WBSubtaskRequest` for task creation.
- Added read-only `tasks` and `task <id>` CLI subcommands mirroring
  `events`/`event`.
- Added Swift Testing coverage for task create (request body and response
  decoding), single-contact create convenience, get-by-id, list-filter query
  construction, and model decoding.

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
- Hardened `WealthboxError.failureReason` so it no longer echoes raw server
  response bodies (which may contain client PII) into user-facing/loggable
  error text; the raw message remains on the case's associated value for
  deliberate, non-user-facing use.
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
