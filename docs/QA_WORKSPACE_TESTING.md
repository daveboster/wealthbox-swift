# QA Workspace Testing (Tier 2)

This package hosts a tier-2 integration suite: package-level tests that run
against a dedicated, non-production **QA** Wealthbox workspace to catch
contract drift the mocked (tier-1) tests cannot. Mocked tests remain the
merge gate; QA runs are an on-demand verification pass, never part of CI.

- Tier 1: mocked/stubbed tests (`WealthboxTests`, `WealthboxQAHarnessTests`)
  — run everywhere, including CI.
- Tier 2: `WealthboxQAIntegrationTests` — this document.
- Tier 3: a consuming app's thin UI smoke subset — can inherit the same
  workspace-identity guard and tagging/sweep hygiene via the `WealthboxQA`
  library product.

## Run Selection

The tier-2 suite runs **only when the QA key is supplied at call time**:
every test is behind `.enabled(if: WEALTHBOX_QA_ACCESS_TOKEN is present)`. A
plain `swift test` — locally or in CI — skips the whole target and constructs
no client, so the standard suites make zero live network calls. Nothing in
any CI workflow sets the variable, and it must stay that way: a live-tenant
failure is a signal about the contract, not about the PR under review.

## Secrets: Keychain Setup And The Wrapper

The QA key lives only in the macOS Keychain and is read at call time by
`bin/wb-qa-run` (a keychain-backed credential wrapper: read the secret at
call time, export it into a single command's environment). It never appears
in the repo, in shell history, or in logs. Runs are local — the tier-2 suite
needs a Mac with the Swift toolchain.

One-time setup, with values from your own private runbook — never commit
them:

```bash
security add-generic-password -U \
  -s wealthbox-swift-qa \
  -a WEALTHBOX_QA_ACCESS_TOKEN \
  -w '<qa-api-key>'

security add-generic-password -U \
  -s wealthbox-swift-qa \
  -a WEALTHBOX_QA_WORKSPACE_ID \
  -w '<qa-workspace-id>'
```

Keychain naming (also used by a human entering the key by hand in Keychain
Access):

| Item | Keychain service | Keychain account |
| --- | --- | --- |
| QA API key | `wealthbox-swift-qa` | `WEALTHBOX_QA_ACCESS_TOKEN` |
| QA workspace id | `wealthbox-swift-qa` | `WEALTHBOX_QA_WORKSPACE_ID` |

The wrapper exports both values into the environment of the one command it
executes. Environment variables that are already set take precedence over
the Keychain (matching `bin/load-wealthbox-token`);
`WEALTHBOX_QA_KEYCHAIN_SERVICE` overrides the service name.

Environment variables read by the suite, guard, and CLI:

| Variable | Meaning | Default |
| --- | --- | --- |
| `WEALTHBOX_QA_ACCESS_TOKEN` | The QA API key; its presence is the run-selection switch | unset (suite skipped) |
| `WEALTHBOX_QA_WORKSPACE_ID` | Expected QA workspace id; required, never defaulted or hardcoded | unset (guard aborts) |
| `WEALTHBOX_QA_WORKSPACE_NAME` | Expected workspace name cross-check; set it to your non-prod workspace's actual name | `QA` |
| `WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER` | Accept a credential that can reach workspaces beyond QA (see guard notes) | off |
| `WEALTHBOX_QA_BASE_URL` | API base override | `https://api.crmworkspace.com` |
| `WEALTHBOX_QA_SEED_HOUSEHOLD` | Seeded household name the tests link artifacts to | `Sample Household` |

## Running

```bash
# 1. Read-only: verify the guard passes and the seed household is present.
bin/wb-qa-run swift run wealthbox-qa verify

# 2. The tier-2 suite.
bin/wb-qa-run swift test --filter WealthboxQAIntegrationTests

# 3. Tenant hygiene: dry-run, then apply.
bin/wb-qa-run swift run wealthbox-qa sweep
bin/wb-qa-run swift run wealthbox-qa sweep --execute
```

`[qa-finding]` lines in the test log are the observations worth recording
and folding back into the tier-1 mocks (error shapes, timings, tag
readback).

## The Workspace-Identity Guard

Wealthbox serves every workspace from one API base, so the loaded credential
is the only thing separating QA from a workspace that holds real client
records. `/v1/me` describes a **login profile**, not a workspace: the
top-level `name` is the user's name, and `accounts` lists every workspace the
login can access — a user-scoped key can list a production CRM alongside QA.
The documented write target is `current_user.account` — "All API calls with
this token will be performed in this user's account (workspace)".

`QAWorkspaceGuard` therefore verifies, failing closed at each step:

1. `WEALTHBOX_QA_WORKSPACE_ID` is set (the expected workspace comes from
   outside the repo; it is never hardcoded);
1. `current_user.account` equals that id — the write target really is QA;
1. the expected id appears in `accounts` **and** carries the expected name
   (default `QA`), so a transposed id cannot pass on id equality alone;
1. **strict sole membership (default):** `accounts` contains only the QA
   workspace, proving the credential cannot reach a production CRM at all.

Tiers 2 and 3 and the sweep all run behind this guard; a refusal aborts
before any write is attempted.

A credential that can reach multiple workspaces is refused even when its
current write target is QA, because nothing proves the target cannot move.
The sanctioned fix is a **dedicated QA-only login** (a user whose only
workspace is QA) and an API key generated for it.
`WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER=1` exists as a deliberate,
documented override and accepts that residual risk; prefer regenerating the
key instead.

## Tenant Data Lifecycle

Fictional households only, seeded by hand. Tests create only notes and
tasks, always linked to a seeded household, and always carrying the run's
markers:

- **Notes** carry the `wb-qa-test` tag plus a per-run `wb-qa-test-run-<runID>`
  tag (tags are a documented note attribute) and a `[wb-qa-test:run:<runID>]`
  marker line in the content.
- **Tasks have no tags field** (tags are documented on Contacts and Notes
  only), so the run marker line in the `description` is the sweep key.

`wealthbox-qa sweep` removes marked artifacts and nothing else:

- Tasks are hard-deleted via the documented `DELETE /v1/tasks/{id}`.
- Notes have **no documented delete endpoint** (`DELETE /v1/notes/{id}` is
  not routed — 404 where routed endpoints return 401 unauthenticated), so
  marked notes are **tombstoned**: `PUT /v1/notes/{id}` rewrites the content
  to a small `[wb-qa-test:swept]` marker, preserving the note's links and
  tags. Already-tombstoned notes are skipped, so sweeps are idempotent.
  Removing a tombstone entirely is a manual Wealthbox UI action, if ever
  needed.

The sweep can never touch the seeded households: it is written against a
narrow operations protocol with no contact operations on it, it runs behind
the identity guard and the wrapper, and unmarked artifacts are only ever
counted, never modified. Tests also clean up what they create; the sweep is
the backstop for interrupted runs.

## Seeding Sample Households (Manual, By Hand)

Sample households are seeded **by hand in the Wealthbox UI** by a human,
once. All data is fictional by construction; no real client data may ever
enter the QA workspace.

Do **not** script this: this package must never gain contact or household
create endpoints. The product only matches contacts — it never creates them
— and the API surface here mirrors the product. Scripted seeding is deferred
unless workspace resets prove frequent.

In the QA workspace (verify the workspace switcher shows the QA workspace
before creating anything), create each **person** as a contact, then a
**household** contact with those persons as household members. Exact control
names may differ slightly by Wealthbox version; the outcome that matters is
at least one household contact whose name matches `WEALTHBOX_QA_SEED_HOUSEHOLD`
(default `Sample Household`), with its members attached. For example:

| Household contact name | Members (person contacts) |
| --- | --- |
| `Sample Household` | Alex Sample; Jordan Sample |

Steps:

1. Contacts → add a **Person** for each member (first/last name is enough;
   add fictional details if richer data is useful).
1. Contacts → add a **Household** whose name matches
   `WEALTHBOX_QA_SEED_HOUSEHOLD` (default `Sample Household`).
1. Open the household and add its member persons under household members
   (set Head/Spouse roles as appropriate).
1. Leave the households untagged: `wb-qa-test` markers belong to
   test-created notes/tasks only, never to seeded contacts.

The suite resolves the seed household by name (`Sample Household` by default)
via contact search at run start and aborts with a pointer to this document
if it is missing. `bin/wb-qa-run swift run wealthbox-qa verify` reports seed
presence read-only.

## Contract Questions → Tests

The tier-2 suite encodes the open contract questions; each test asserts the
doc-derived expectation so a live failure is a drift finding:

| Contract question | Test |
| --- | --- |
| `/v1/me` fields sufficient for the guard | `identityGuardVerifiesQAWorkspace` |
| Seeded-household matchability | `seededHouseholdIsPresentForLinking` |
| Notes accept tags (tagging convention) | `noteCreateAcceptsTagsAndMarkerRoundTrips` |
| Update-vs-append note semantics | `noteUpdateReplacesContentInsteadOfAppending` |
| Tasks accept tags (docs say no) | `taskCreateCarriesMarkerAndHasNoTagsField` |
| Task delete endpoint + not-found error shape | `taskDeleteRemovesTaskAndYieldsNotFoundShape` |
| Note delete endpoint (docs: none) → live tombstone hygiene | `noteHygieneUsesTombstoneSinceNotesHaveNoDelete` |
| Rate limits vs the one-note-plus-N-tasks save fan-out | `saveFanOutSurvivesDocumentedThrottle` |
| Error shapes for tier-1 mocks | `unauthorizedErrorShapeForInvalidToken` + `[qa-finding]` records |

Documented baseline (dev.wealthbox.com): throttling is one request/second
averaged over a five-minute sampling period with short bursts permitted, and
429 signals the limit (no `Retry-After` header is documented — observing
whether one is sent is part of the fan-out test). `POST /v1/notes` and
`PUT /v1/notes/{id}` document `content` (required), `linked_to`,
`visible_to`, and `tags`; task create/update document no `tags` field;
`GET /v1/categories/tags?document_type=` offers `Contact` and `Note` only;
`GET /v1/notes` returns notes under a `status_updates` key;
`DELETE /v1/tasks/{id}` responds 200 with the deleted task body.
