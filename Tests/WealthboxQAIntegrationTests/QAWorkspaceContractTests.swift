import Foundation
import Testing
import Wealthbox
import WealthboxQA

/// Tier-2 QA-workspace integration tests.
///
/// These encode the open Wealthbox contract questions as live tests: each
/// test asserts the doc-derived expectation, so a failure against the real
/// tenant *is* a contract-drift finding, and `[qa-finding]`
/// lines in the log capture the observations worth folding back into the
/// tier-1 mocks.
///
/// Run selection: the whole suite is skipped unless
/// `WEALTHBOX_QA_ACCESS_TOKEN` is supplied at call time — run it via
/// `bin/wb-qa-run swift test --filter WealthboxQAIntegrationTests`.
/// It never runs in a CI merge path. Every test draws on the memoized
/// `QASession` bootstrap, so the `/v1/me` workspace-identity guard runs
/// once and a refusal fails every test before any write is attempted.
///
/// Tenant hygiene: every artifact carries the run id (note tags + marker
/// lines per `QAArtifactMarker`), tests clean up what they create, and
/// `wealthbox-qa sweep` is the backstop. Nothing here creates, updates,
/// or deletes contacts — the seeded households are matched, never written.
@Suite(
    .serialized,
    .enabled(
        if: QASession.environment.isConfigured,
        "QA run not requested: WEALTHBOX_QA_ACCESS_TOKEN is absent. Use bin/wb-qa-run."
    )
)
struct QAWorkspaceContractTests {
    // MARK: - Contract question: /v1/me fields sufficient for the guard

    @Test("Identity guard verifies the QA workspace from /v1/me")
    func identityGuardVerifiesQAWorkspace() throws {
        let context = try QASession.requireContext()

        #expect(context.identity.workspaceID == QASession.environment.expectedWorkspaceID)
        #expect(!context.identity.userName.isEmpty)
        #expect(!context.identity.userEmail.isEmpty)
        QAFindings.record(context.identity.summary)
        QAFindings.record("run id: \(QASession.runID)")
    }

    @Test("Seeded household is present and matchable for linking")
    func seededHouseholdIsPresentForLinking() throws {
        let context = try QASession.requireContext()

        #expect(context.seedContactID > 0)
        QAFindings.record(
            "seed household: \(context.seedContactName) (contact id \(context.seedContactID))"
        )
    }

    // MARK: - Contract question: do notes accept tags? (tagging convention)

    @Test("Note create accepts the documented tags array and the run marker round-trips")
    func noteCreateAcceptsTagsAndMarkerRoundTrips() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID
        let content = QAArtifactMarker.marked(
            "Tier-2 contract check: note create with tags.",
            runID: runID
        )

        let created = try context.client.createNote(
            content: content,
            linkedTo: [WBNoteLink(id: context.seedContactID, type: "Contact")],
            tags: QAArtifactMarker.noteTags(runID: runID)
        )
        let createdID = try #require(created.id)
        QASession.pace()

        let fetched = try context.client.getNote(id: createdID)
        let fetchedTagNames = (fetched.tags ?? []).compactMap(\.name)
        QAFindings.record(
            "note \(createdID) create with tags -> readback tags: \(fetchedTagNames)"
        )

        #expect(QAArtifactMarker.isMarked(fetched.content, runID: runID))
        #expect(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)
        // Docs list `tags: Array (string)` on note create; drift here breaks
        // the documented tagging convention for notes.
        #expect(fetchedTagNames.contains(QAArtifactMarker.baseTag))
        #expect(fetchedTagNames.contains("\(QAArtifactMarker.runTagPrefix)\(runID.rawValue)"))

        QASession.pace()
        try tombstone(note: fetched, context: context)
    }

    // MARK: - Contract question: update-vs-append note semantics

    @Test("Note update replaces content in place (update, not append)")
    func noteUpdateReplacesContentInsteadOfAppending() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID
        let originalContent = QAArtifactMarker.marked(
            "Tier-2 contract check: original canonical note body.",
            runID: runID
        )
        let replacementContent = QAArtifactMarker.marked(
            "Tier-2 contract check: replacement canonical note body.",
            runID: runID
        )

        let created = try context.client.createNote(
            content: originalContent,
            linkedTo: [WBNoteLink(id: context.seedContactID, type: "Contact")],
            tags: QAArtifactMarker.noteTags(runID: runID)
        )
        let createdID = try #require(created.id)
        QASession.pace()

        let updated = try context.client.updateNote(
            id: createdID,
            content: replacementContent,
            linkedTo: [WBNoteLink(id: context.seedContactID, type: "Contact")],
            tags: QAArtifactMarker.noteTags(runID: runID)
        )
        #expect(updated.id == createdID)
        QASession.pace()

        let fetched = try context.client.getNote(id: createdID)
        let fetchedContent = try #require(fetched.content)
        QAFindings.record(
            "note \(createdID) after PUT: content length \(fetchedContent.count), tags \((fetched.tags ?? []).compactMap(\.name))"
        )

        // The canonical-household-note flow (Deliverable 2.2) requires
        // update-not-append: the PUT body must replace the content.
        #expect(fetchedContent.contains("replacement canonical note body"))
        #expect(!fetchedContent.contains("original canonical note body"))
        #expect(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)

        QASession.pace()
        try tombstone(note: fetched, context: context)
    }

    // MARK: - Contract question: do tasks accept tags?

    @Test("Task has no tags field; the run marker rides the description as the sweep key")
    func taskCreateCarriesMarkerAndHasNoTagsField() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID

        // Tasks have no documented `tags` field (tags are documented on
        // Contacts and Notes only — confirmed doc-side and by an
        // unauthenticated routing probe), and the typed client exposes no
        // way to set them. So the tagging convention cannot apply to tasks;
        // what must hold live is the
        // fallback — the run marker rides the `description`, which is the
        // sweep key for tasks.
        let created = try context.client.createTask(
            name: "Tier-2 contract check: task marker",
            dueDate: QASession.testDueDate(),
            description: QAArtifactMarker.marked(
                "Confirm the run marker rides a task's description.",
                runID: runID
            ),
            linkedTo: [WBTaskLink(id: context.seedContactID, type: "Contact")]
        )
        let taskID = try #require(created.id)
        QASession.pace()

        let fetched = try context.client.getTask(id: taskID)
        QAFindings.record(
            "task \(taskID) readback: description marker present=\(QAArtifactMarker.isMarked(fetched.description, runID: runID)), linked to seed=\(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)"
        )

        // The sweep keys on this marker for tasks; assert it survives a
        // create/readback round-trip and the household link holds.
        #expect(QAArtifactMarker.isMarked(fetched.description, runID: runID))
        #expect(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)

        QASession.pace()
        try context.client.deleteTask(id: taskID)
    }

    // MARK: - Contract question: delete endpoints for tenant hygiene

    @Test("Task delete removes the task and yields the not-found error shape")
    func taskDeleteRemovesTaskAndYieldsNotFoundShape() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID

        let created = try context.client.createTask(
            name: "Tier-2 contract check: task delete",
            dueDate: QASession.testDueDate(),
            description: QAArtifactMarker.marked("Delete-endpoint check.", runID: runID),
            linkedTo: [WBTaskLink(id: context.seedContactID, type: "Contact")]
        )
        let taskID = try #require(created.id)
        QASession.pace()

        let deleted = try context.client.deleteTask(id: taskID)
        // Docs: DELETE /v1/tasks/{id} responds 200 with the deleted task body.
        #expect(deleted.id == taskID)
        QASession.pace()

        do {
            _ = try context.client.getTask(id: taskID)
            Issue.record("Task \(taskID) is still retrievable after DELETE.")
        } catch let error as WealthboxError {
            // Worth folding into the tier-1 mocks: the observed error shape
            // for a deleted/unknown task id.
            QAFindings.record("GET deleted task -> \(error)")
        }
    }

    @Test("Notes have no delete endpoint; tombstoning is the live hygiene path")
    func noteHygieneUsesTombstoneSinceNotesHaveNoDelete() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID

        // Wealthbox documents no notes DELETE, and an unauthenticated probe
        // found the path unrouted (404 where routed endpoints return 401).
        // So the sweep's note-disposal path is a PUT
        // tombstone, not a delete. Confirm that hygiene path works live: the
        // content is replaced with the swept marker while the household link
        // and the run marker survive.
        let created = try context.client.createNote(
            content: QAArtifactMarker.marked("Note pending tombstone.", runID: runID),
            linkedTo: [WBNoteLink(id: context.seedContactID, type: "Contact")],
            tags: QAArtifactMarker.noteTags(runID: runID)
        )
        let noteID = try #require(created.id)
        QASession.pace()

        try tombstone(note: created, context: context)
        QASession.pace()

        let fetched = try context.client.getNote(id: noteID)
        QAFindings.record(
            "note \(noteID) tombstoned: isTombstone=\(QAArtifactMarker.isTombstone(fetched.content)), links preserved=\(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)"
        )

        #expect(fetched.id == noteID)
        #expect(QAArtifactMarker.isTombstone(fetched.content))
        #expect(QAArtifactMarker.isMarked(fetched.content, runID: runID))
        #expect(fetched.linkedTo?.contains { $0.id == context.seedContactID } == true)
    }

    // MARK: - Contract question: rate limits vs the save fan-out

    @Test("One-note-plus-five-tasks save fan-out survives the documented burst tolerance")
    func saveFanOutSurvivesDocumentedThrottle() throws {
        let context = try QASession.requireContext()
        let runID = QASession.runID
        let start = Date()
        var createdTaskIDs: [Int] = []

        // The 1.1/1.2 save shape: one summary note plus N action-item tasks,
        // fired back-to-back with no client-side pacing. Wealthbox documents
        // one request/second sustained over a five-minute sampling window
        // with short bursts permitted; this measures whether a realistic
        // six-write burst rides that tolerance.
        do {
            let note = try context.client.createNote(
                content: QAArtifactMarker.marked("Fan-out probe: meeting summary note.", runID: runID),
                linkedTo: [WBNoteLink(id: context.seedContactID, type: "Contact")],
                tags: QAArtifactMarker.noteTags(runID: runID)
            )
            let noteID = try #require(note.id)

            for index in 1...5 {
                let task = try context.client.createTask(
                    name: "Fan-out probe action \(index)",
                    dueDate: QASession.testDueDate(),
                    description: QAArtifactMarker.marked("Fan-out probe action \(index).", runID: runID),
                    linkedTo: [WBTaskLink(id: context.seedContactID, type: "Contact")]
                )
                createdTaskIDs.append(try #require(task.id))
            }

            let elapsed = Date().timeIntervalSince(start)
            QAFindings.record(String(format: "fan-out: 6 writes in %.2fs with no 429", elapsed))

            // Cleanup, paced.
            for taskID in createdTaskIDs {
                QASession.pace()
                try context.client.deleteTask(id: taskID)
            }
            QASession.pace()
            let fetched = try context.client.getNote(id: noteID)
            try tombstone(note: fetched, context: context)
        } catch let error as WealthboxError {
            guard case .rateLimited(let retryAfter) = error else {
                throw error
            }
            // A 429 inside a six-write burst is itself the finding the
            // strategy asked for — record the observed Retry-After before
            // failing so the save fan-out design can react to it. Any note
            // or task left behind carries the run marker; the sweep is the
            // backstop.
            QAFindings.record(
                "fan-out hit 429; Retry-After: \(retryAfter.map(String.init) ?? "absent")"
            )
            for taskID in createdTaskIDs {
                QASession.pace()
                try? context.client.deleteTask(id: taskID)
            }
            throw error
        }
    }

    // MARK: - Contract question: error shapes for the tier-1 mocks

    @Test("Invalid token yields the documented unauthorized error shape")
    func unauthorizedErrorShapeForInvalidToken() throws {
        _ = try QASession.requireContext()

        let badClient = WealthboxApiClient(
            baseURL: QASession.environment.baseURL,
            accessToken: "invalid-token-for-error-shape-probe"
        )
        do {
            _ = try badClient.getCurrentUser()
            Issue.record("Expected an invalid token to be rejected.")
        } catch let error as WealthboxError {
            guard case .unauthorized(let message) = error else {
                Issue.record("Expected .unauthorized, got \(error)")
                return
            }
            // The body shape is mock-foldback material for tier 1.
            QAFindings.record("401 body: \(message.prefix(200))")
        }
    }

    // MARK: - Helpers

    /// Test-side cleanup mirroring the sweep's disposal rule for notes:
    /// no delete endpoint exists, so the content is tombstoned in place,
    /// preserving links and wb-qa-test tags.
    private func tombstone(note: WBNote, context: QAContext) throws {
        guard let id = note.id else { return }
        var tags = (note.tags ?? []).compactMap(\.name)
        if !tags.contains(QAArtifactMarker.baseTag) {
            tags.append(QAArtifactMarker.baseTag)
        }
        try context.client.updateNote(
            id: id,
            content: QAArtifactMarker.tombstoneContent(
                runID: QAArtifactMarker.runID(in: note.content)
            ),
            linkedTo: note.linkedTo,
            visibleTo: note.visibleTo,
            tags: tags
        )
    }
}
