import ArgumentParser
import Foundation
import Wealthbox
import WealthboxQA

@main
struct WealthboxQACommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wealthbox-qa",
        abstract: "QA-workspace test tooling: identity verification and tenant-hygiene sweep.",
        discussion: """
        Every subcommand runs behind the /v1/me workspace-identity guard and \
        reads its configuration from WEALTHBOX_QA_* environment \
        variables supplied at call time. There is no --token option on \
        purpose: run through bin/wb-qa-run so the QA key is read \
        from the macOS Keychain and never lands in shell history.
        """,
        subcommands: [
            Verify.self,
            Sweep.self
        ]
    )
}

private func verifiedIdentity(environment: QARunEnvironment) throws -> (WealthboxApiClient, QAWorkspaceIdentity) {
    let client = environment.makeClient()
    let identity = try QAWorkspaceGuard.verify(client: client, environment: environment)
    return (client, identity)
}

struct Verify: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Run the QA workspace-identity guard and report what it verified. Read-only."
    )

    func run() throws {
        let environment = QARunEnvironment.fromProcessEnvironment()
        let (client, identity) = try verifiedIdentity(environment: environment)
        print(identity.summary)

        let seedName = environment.seedHouseholdName
        let matches = try client.searchContacts(name: seedName, type: "household").contacts
            .filter { contact in
                guard let name = contact.name else { return false }
                return name.range(of: seedName, options: .caseInsensitive) != nil
            }
        if matches.isEmpty {
            print("Seed household \"\(seedName)\": NOT FOUND — seed the sample households by hand first (docs/QA_WORKSPACE_TESTING.md).")
        } else {
            let described = matches.map { "\($0.name ?? "?") (\($0.id.map { String($0) } ?? "?"))" }
                .joined(separator: ", ")
            print("Seed household \"\(seedName)\": \(described)")
        }
    }
}

struct Sweep: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sweep",
        abstract: "Find and remove wb-qa-test-marked QA artifacts. Dry-run by default.",
        discussion: """
        Selection is marker-strict: only notes/tasks carrying the \
        wb-qa-test convention (run-marker line, or wb-qa-test tags on \
        notes) are touched. Tasks are hard-deleted (DELETE /v1/tasks/{id}); \
        notes have no documented delete endpoint, so they are tombstoned in \
        place via PUT, preserving their links and tags. The sweep has no \
        contact operations at all, so seeded households are structurally out \
        of reach. Pass --execute to apply the plan.
        """
    )

    @Option(help: "Only sweep artifacts from one run id (e.g. 20260714-033320-a1b2).")
    var runId: String?

    @Flag(help: "Apply the plan. Without this flag the sweep only prints what it would do.")
    var execute = false

    @Flag(help: "Sweep tasks only; leave marked notes untouched.")
    var skipNotes = false

    func run() throws {
        let environment = QARunEnvironment.fromProcessEnvironment()
        let (client, identity) = try verifiedIdentity(environment: environment)
        print(identity.summary)

        var scopedRunID: QARunID?
        if let runId {
            guard let parsed = QARunID(rawValue: runId) else {
                throw ValidationError("Invalid run id '\(runId)'. Expected the yyyyMMdd-HHmmss-xxxx format.")
            }
            scopedRunID = parsed
        }

        let plan = try QASweeper.plan(
            operations: client,
            runID: scopedRunID,
            includeNotes: !skipNotes
        )

        print("")
        print("Sweep plan\(scopedRunID.map { " (run \($0))" } ?? ""):")
        for target in plan.taskTargets {
            print("  delete task \(target.id): \(target.name ?? "(unnamed)")\(target.runID.map { " [run \($0)]" } ?? "")")
        }
        for target in plan.noteTargets {
            print("  tombstone note \(target.id)\(target.runID.map { " [run \($0)]" } ?? "")")
        }
        if plan.isEmpty {
            print("  nothing to sweep")
        }
        print("  (left alone: \(plan.skippedTaskCount) unmarked tasks, \(plan.skippedNoteCount) unmarked notes, \(plan.alreadySweptNoteCount) already-swept notes)")
        if plan.truncated {
            print("  WARNING: listing hit the page cap; re-run the sweep to catch the remainder.")
        }

        guard execute else {
            print("")
            print("Dry run only. Re-run with --execute to apply.")
            return
        }

        let report = try QASweeper.execute(plan: plan, operations: client) {
            Thread.sleep(forTimeInterval: 1.1)
        }
        print("")
        print("Swept: deleted \(report.deletedTaskIDs.count) tasks (\(report.alreadyGoneTaskIDs.count) already gone), tombstoned \(report.tombstonedNoteIDs.count) notes.")
    }
}
