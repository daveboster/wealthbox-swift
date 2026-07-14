import Foundation
import Testing
import Wealthbox
@testable import WealthboxQA

/// A scripted `QASweepOperations` fake. The sweeper is written against
/// that narrow protocol — with no contact operations on it, seeded households
/// are unreachable from sweep code by construction.
private final class FakeSweepOperations: QASweepOperations {
    var openTasks: [WBTask] = []
    var completedTasks: [WBTask] = []
    var notes: [WBNote] = []
    var deleteTaskThrows404ForIDs: Set<Int> = []

    private(set) var deletedTaskIDs: [Int] = []
    private(set) var noteUpdates: [(id: Int, content: String, linkedTo: [WBNoteLink]?, visibleTo: String?, tags: [String]?)] = []
    private(set) var taskListRequests: [WBTaskListFilters] = []
    private(set) var noteListRequests: [WBNoteListFilters] = []

    func getTasks(filters: WBTaskListFilters) throws -> WBTasks {
        taskListRequests.append(filters)
        let source = filters.completed == true ? completedTasks : openTasks
        return WBTasks(page(source, filters.page, filters.perPage), page: filters.page, perPage: filters.perPage)
    }

    func deleteTask(id: Int) throws -> WBTask {
        if deleteTaskThrows404ForIDs.contains(id) {
            throw WealthboxError.serverError(code: 404, message: "Not found")
        }
        deletedTaskIDs.append(id)
        return try WBTask.decode("{\"id\": \(id)}")
    }

    func getNotes(filters: WBNoteListFilters) throws -> WBNotes {
        noteListRequests.append(filters)
        return WBNotes(page(notes, filters.page, filters.perPage), page: filters.page, perPage: filters.perPage)
    }

    func updateNote(
        id: Int,
        content: String,
        linkedTo: [WBNoteLink]?,
        visibleTo: String?,
        tags: [String]?
    ) throws -> WBNote {
        noteUpdates.append((id, content, linkedTo, visibleTo, tags))
        return try WBNote.decode("{\"id\": \(id)}")
    }

    private func page<Item>(_ items: [Item], _ page: Int?, _ perPage: Int?) -> [Item] {
        let size = perPage ?? 50
        let index = max((page ?? 1) - 1, 0)
        let start = index * size
        guard start < items.count else { return [] }
        return Array(items[start..<min(start + size, items.count)])
    }
}

private func task(id: Int, name: String = "Task", description: String?, complete: Bool = false) throws -> WBTask {
    let descriptionJSON = description.map { "\"description\": \"\(escaped($0))\"," } ?? ""
    return try WBTask.decode("""
    {"id": \(id), "name": "\(name)", \(descriptionJSON) "complete": \(complete)}
    """)
}

private func note(id: Int, content: String?, tagNames: [String] = [], linkedContactID: Int? = nil) throws -> WBNote {
    let contentJSON = content.map { "\"content\": \"\(escaped($0))\"," } ?? ""
    let tagsJSON = tagNames.enumerated()
        .map { "{\"id\": \($0.offset + 1), \"name\": \"\($0.element)\"}" }
        .joined(separator: ", ")
    let linkedJSON = linkedContactID.map {
        "\"linked_to\": [{\"id\": \($0), \"type\": \"Contact\", \"name\": \"Seeded Household\"}],"
    } ?? ""
    return try WBNote.decode("""
    {"id": \(id), \(contentJSON) \(linkedJSON) "tags": [\(tagsJSON)]}
    """)
}

private func escaped(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
}

struct QASweeperTests {
    private let runID = QARunID.generate(
        date: Date(timeIntervalSince1970: 1_784_000_000),
        suffix: "a1b2"
    )
    private let otherRunID = QARunID.generate(
        date: Date(timeIntervalSince1970: 1_784_000_000),
        suffix: "z9z9"
    )

    @Test
    func planSelectsOnlyMarkedArtifactsAndSkipsTheRest() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = [
            try task(id: 1, description: QAArtifactMarker.marked("Follow up", runID: runID)),
            try task(id: 2, description: "A real advisor task, never touched"),
            try task(id: 3, description: nil)
        ]
        ops.completedTasks = [
            try task(id: 4, description: QAArtifactMarker.marked("Done item", runID: runID), complete: true)
        ]
        ops.notes = [
            try note(id: 10, content: QAArtifactMarker.marked("Meeting summary", runID: runID), tagNames: ["wb-qa-test"], linkedContactID: 42),
            try note(id: 11, content: "A real client note"),
            // Tag-only marked note (content marker missing): still swept.
            try note(id: 12, content: "Tagged but unmarked content", tagNames: ["wb-qa-test"]),
            // Already tombstoned by an earlier sweep: left alone.
            try note(id: 13, content: QAArtifactMarker.tombstoneContent(runID: runID), tagNames: ["wb-qa-test"])
        ]

        let plan = try QASweeper.plan(operations: ops)

        #expect(plan.taskTargets.map(\.id) == [1, 4])
        #expect(plan.taskTargets.first?.runID == runID)
        #expect(plan.noteTargets.map(\.id) == [10, 12])
        #expect(plan.skippedTaskCount == 2)
        #expect(plan.skippedNoteCount == 1)
        #expect(plan.alreadySweptNoteCount == 1)
        #expect(!plan.truncated)
        #expect(!plan.isEmpty)
    }

    @Test
    func planScopedToARunIgnoresOtherRunsArtifacts() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = [
            try task(id: 1, description: QAArtifactMarker.marked("Mine", runID: runID)),
            try task(id: 2, description: QAArtifactMarker.marked("Other run", runID: otherRunID))
        ]
        ops.notes = [
            try note(id: 10, content: QAArtifactMarker.marked("Mine", runID: runID)),
            try note(id: 11, content: "No marker", tagNames: ["wb-qa-test-run-\(otherRunID.rawValue)"]),
            try note(id: 12, content: "No marker", tagNames: ["wb-qa-test-run-\(runID.rawValue)"])
        ]

        let plan = try QASweeper.plan(operations: ops, runID: runID)

        #expect(plan.taskTargets.map(\.id) == [1])
        #expect(plan.noteTargets.map(\.id) == [10, 12])
    }

    @Test
    func planCanExcludeNotes() throws {
        let ops = FakeSweepOperations()
        ops.notes = [try note(id: 10, content: QAArtifactMarker.marked("x", runID: runID))]

        let plan = try QASweeper.plan(operations: ops, includeNotes: false)

        #expect(plan.noteTargets.isEmpty)
        #expect(ops.noteListRequests.isEmpty)
    }

    @Test
    func planPaginatesUntilAShortPage() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = try (1...5).map {
            try task(id: $0, description: QAArtifactMarker.marked("t\($0)", runID: runID))
        }

        let plan = try QASweeper.plan(operations: ops, perPage: 2)

        #expect(plan.taskTargets.count == 5)
        #expect(!plan.truncated)
        // Three pages for the open pass (2 + 2 + 1), one for completed, one
        // page of notes.
        let openPages = ops.taskListRequests.filter { $0.completed == false }.compactMap(\.page)
        #expect(openPages == [1, 2, 3])
    }

    @Test
    func planReportsTruncationWhenPageCapIsHit() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = try (1...6).map {
            try task(id: $0, description: QAArtifactMarker.marked("t\($0)", runID: runID))
        }

        let plan = try QASweeper.plan(operations: ops, perPage: 2, pageLimit: 2)

        #expect(plan.truncated)
        #expect(plan.taskTargets.count == 4)
    }

    @Test
    func executeDeletesTasksAndTombstonesNotesPreservingLinksAndTags() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = [
            try task(id: 1, description: QAArtifactMarker.marked("Follow up", runID: runID))
        ]
        ops.notes = [
            try note(id: 10, content: QAArtifactMarker.marked("Summary", runID: runID), tagNames: ["wb-qa-test", "wb-qa-test-run-\(runID.rawValue)"], linkedContactID: 42)
        ]
        let plan = try QASweeper.plan(operations: ops)
        nonisolated(unsafe) var paceCount = 0

        let report = try QASweeper.execute(plan: plan, operations: ops) { paceCount += 1 }

        #expect(report.deletedTaskIDs == [1])
        #expect(report.alreadyGoneTaskIDs.isEmpty)
        #expect(report.tombstonedNoteIDs == [10])
        #expect(ops.deletedTaskIDs == [1])
        #expect(paceCount == 2)

        let update = try #require(ops.noteUpdates.first)
        #expect(update.id == 10)
        #expect(QAArtifactMarker.isTombstone(update.content))
        #expect(QAArtifactMarker.runID(in: update.content) == runID)
        #expect(update.linkedTo?.map(\.id) == [42])
        #expect(update.tags == ["wb-qa-test", "wb-qa-test-run-\(runID.rawValue)"])
    }

    @Test
    func executeTreats404DeletesAsAlreadyGone() throws {
        let ops = FakeSweepOperations()
        ops.openTasks = [
            try task(id: 1, description: QAArtifactMarker.marked("Parent", runID: runID)),
            try task(id: 2, description: QAArtifactMarker.marked("Subtask removed with parent", runID: runID))
        ]
        ops.deleteTaskThrows404ForIDs = [2]
        let plan = try QASweeper.plan(operations: ops)

        let report = try QASweeper.execute(plan: plan, operations: ops)

        #expect(report.deletedTaskIDs == [1])
        #expect(report.alreadyGoneTaskIDs == [2])
    }

    @Test
    func executeAddsBaseTagWhenAMarkedNoteLacksIt() throws {
        let ops = FakeSweepOperations()
        ops.notes = [
            try note(id: 10, content: QAArtifactMarker.marked("Summary", runID: runID), tagNames: ["Meeting"])
        ]
        let plan = try QASweeper.plan(operations: ops)

        _ = try QASweeper.execute(plan: plan, operations: ops)

        let update = try #require(ops.noteUpdates.first)
        #expect(update.tags == ["Meeting", "wb-qa-test"])
    }
}
