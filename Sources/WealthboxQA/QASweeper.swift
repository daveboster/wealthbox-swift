import Foundation
import Wealthbox

/// The only Wealthbox operations the sweep is able to perform. The sweeper is
/// written against this narrow surface — not the full client — so it is
/// structurally incapable of touching contacts or households: there is no
/// contact operation to call. Seeded households are contacts, so they are
/// unreachable by construction.
public protocol QASweepOperations {
    func getTasks(filters: WBTaskListFilters) throws -> WBTasks
    @discardableResult func deleteTask(id: Int) throws -> WBTask
    func getNotes(filters: WBNoteListFilters) throws -> WBNotes
    @discardableResult func updateNote(
        id: Int,
        content: String,
        linkedTo: [WBNoteLink]?,
        visibleTo: String?,
        tags: [String]?
    ) throws -> WBNote
}

extension WealthboxApiClient: QASweepOperations {}

/// Finds and removes QA-workspace artifacts created by tier-2/tier-3
/// runs. Selection is marker-strict: an artifact qualifies only if it carries
/// the wb-qa-test convention (`QAArtifactMarker`) — a run marker line
/// in its body/description, or (for notes) the wb-qa-test tags. Anything
/// else is reported as skipped, never touched.
///
/// Disposal differs by artifact type because the API differs:
/// - **Tasks** are hard-deleted via the documented `DELETE /v1/tasks/{id}`.
/// - **Notes** have no documented delete endpoint (`DELETE /v1/notes/{id}` is
///   not even routed), so marked notes are *tombstoned*: `PUT /v1/notes/{id}`
///   rewrites the content to a small swept marker while preserving the note's
///   links and its wb-qa-test tags. Already-tombstoned notes are left
///   alone, so sweeps are idempotent.
public enum QASweeper {
    public struct Plan: Sendable {
        public struct TaskTarget: Sendable {
            public let id: Int
            public let name: String?
            public let runID: QARunID?
        }

        public struct NoteTarget: Sendable {
            public let id: Int
            public let runID: QARunID?
            public let linkedTo: [WBNoteLink]?
            public let visibleTo: String?
            public let tags: [String]
        }

        public let taskTargets: [TaskTarget]
        public let noteTargets: [NoteTarget]
        /// Marked notes already tombstoned by an earlier sweep.
        public let alreadySweptNoteCount: Int
        /// Unmarked artifacts seen and deliberately left alone.
        public let skippedTaskCount: Int
        public let skippedNoteCount: Int
        /// True when a listing hit the page cap; the sweep may be incomplete
        /// and should be re-run.
        public let truncated: Bool

        public var isEmpty: Bool { taskTargets.isEmpty && noteTargets.isEmpty }
    }

    public struct Report: Sendable {
        public let deletedTaskIDs: [Int]
        /// Tasks that were already gone when deleted (e.g. removed with a
        /// parent task earlier in the same sweep).
        public let alreadyGoneTaskIDs: [Int]
        public let tombstonedNoteIDs: [Int]
    }

    /// Lists tasks and notes, returning the marker-qualified targets.
    ///
    /// - Parameters:
    ///   - runID: When set, only artifacts carrying that run's marker
    ///     qualify; otherwise every wb-qa-test-marked artifact qualifies.
    ///   - includeNotes: Pass `false` to plan a tasks-only sweep.
    ///   - perPage: Page size for listings.
    ///   - pageLimit: Safety cap on pages fetched per listing; `truncated`
    ///     reports if it was hit.
    public static func plan(
        operations: any QASweepOperations,
        runID: QARunID? = nil,
        includeNotes: Bool = true,
        perPage: Int = 50,
        pageLimit: Int = 40
    ) throws -> Plan {
        var truncated = false

        var tasks: [WBTask] = []
        // The documented `completed` filter is a flag, so open and completed
        // tasks are listed in separate passes.
        for completed in [false, true] {
            let pages = try paginate(pageLimit: pageLimit, truncated: &truncated) { page in
                let list = try operations.getTasks(filters: WBTaskListFilters(
                    completed: completed,
                    page: page,
                    perPage: perPage
                ))
                return (list.tasks, list.tasks.count < perPage)
            }
            tasks.append(contentsOf: pages)
        }

        var seenTaskIDs = Set<Int>()
        var taskTargets: [Plan.TaskTarget] = []
        var skippedTaskCount = 0
        for task in tasks {
            guard let id = task.id, seenTaskIDs.insert(id).inserted else { continue }
            guard qualifies(text: task.description, runID: runID) else {
                skippedTaskCount += 1
                continue
            }
            taskTargets.append(Plan.TaskTarget(
                id: id,
                name: task.name,
                runID: QAArtifactMarker.runID(in: task.description)
            ))
        }

        var noteTargets: [Plan.NoteTarget] = []
        var skippedNoteCount = 0
        var alreadySweptNoteCount = 0
        if includeNotes {
            let notes = try paginate(pageLimit: pageLimit, truncated: &truncated) { page in
                let list = try operations.getNotes(filters: WBNoteListFilters(
                    page: page,
                    perPage: perPage
                ))
                return (list.notes, list.notes.count < perPage)
            }

            var seenNoteIDs = Set<Int>()
            for note in notes {
                guard let id = note.id, seenNoteIDs.insert(id).inserted else { continue }
                let tagNames = (note.tags ?? []).compactMap(\.name)
                let markedByContent = qualifies(text: note.content, runID: runID)
                let markedByTags = runID == nil
                    ? QAArtifactMarker.hasTestTag(tagNames)
                    : tagNames.contains("\(QAArtifactMarker.runTagPrefix)\(runID!.rawValue)")
                guard markedByContent || markedByTags else {
                    skippedNoteCount += 1
                    continue
                }
                if QAArtifactMarker.isTombstone(note.content) {
                    alreadySweptNoteCount += 1
                    continue
                }
                var tags = tagNames
                if !tags.contains(QAArtifactMarker.baseTag) {
                    tags.append(QAArtifactMarker.baseTag)
                }
                noteTargets.append(Plan.NoteTarget(
                    id: id,
                    runID: QAArtifactMarker.runID(in: note.content),
                    linkedTo: note.linkedTo,
                    visibleTo: note.visibleTo,
                    tags: tags
                ))
            }
        }

        return Plan(
            taskTargets: taskTargets,
            noteTargets: noteTargets,
            alreadySweptNoteCount: alreadySweptNoteCount,
            skippedTaskCount: skippedTaskCount,
            skippedNoteCount: skippedNoteCount,
            truncated: truncated
        )
    }

    /// Executes a plan: deletes each task target, tombstones each note
    /// target. `pace` runs between write calls so a large sweep can respect
    /// Wealthbox's documented one-request-per-second throttle.
    public static func execute(
        plan: Plan,
        operations: any QASweepOperations,
        pace: () -> Void = {}
    ) throws -> Report {
        var deletedTaskIDs: [Int] = []
        var alreadyGoneTaskIDs: [Int] = []
        for target in plan.taskTargets {
            do {
                try operations.deleteTask(id: target.id)
                deletedTaskIDs.append(target.id)
            } catch let error as WealthboxError {
                if case .serverError(let code, _) = error, code == 404 {
                    alreadyGoneTaskIDs.append(target.id)
                } else {
                    throw error
                }
            }
            pace()
        }

        var tombstonedNoteIDs: [Int] = []
        for target in plan.noteTargets {
            try operations.updateNote(
                id: target.id,
                content: QAArtifactMarker.tombstoneContent(runID: target.runID),
                linkedTo: target.linkedTo,
                visibleTo: target.visibleTo,
                tags: target.tags
            )
            tombstonedNoteIDs.append(target.id)
            pace()
        }

        return Report(
            deletedTaskIDs: deletedTaskIDs,
            alreadyGoneTaskIDs: alreadyGoneTaskIDs,
            tombstonedNoteIDs: tombstonedNoteIDs
        )
    }

    private static func qualifies(text: String?, runID: QARunID?) -> Bool {
        if let runID {
            return QAArtifactMarker.isMarked(text, runID: runID)
        }
        return QAArtifactMarker.isMarked(text)
    }

    private static func paginate<Item>(
        pageLimit: Int,
        truncated: inout Bool,
        fetch: (Int) throws -> (items: [Item], isLastPage: Bool)
    ) rethrows -> [Item] {
        var collected: [Item] = []
        var page = 1
        while page <= pageLimit {
            let (items, isLastPage) = try fetch(page)
            collected.append(contentsOf: items)
            if items.isEmpty || isLastPage {
                return collected
            }
            page += 1
        }
        truncated = true
        return collected
    }
}
