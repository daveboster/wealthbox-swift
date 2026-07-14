import Foundation
import Testing
@testable import WealthboxQA

struct QARunIDTests {
    @Test
    func generateProducesValidDeterministicID() {
        let date = Date(timeIntervalSince1970: 1_784_000_000) // 2026-07-14 03:33:20 UTC
        let id = QARunID.generate(date: date, suffix: "a1b2")

        #expect(id.rawValue == "20260714-033320-a1b2")
        #expect(QARunID.isValid(id.rawValue))
    }

    @Test
    func generateWithoutSuffixIsValid() {
        let id = QARunID.generate()

        #expect(QARunID.isValid(id.rawValue))
    }

    @Test
    func invalidInjectedSuffixFallsBackToARandomValidID() {
        let id = QARunID.generate(suffix: "NOT VALID")

        #expect(QARunID.isValid(id.rawValue))
    }

    @Test
    func rawValueInitRejectsMalformedIDs() {
        #expect(QARunID(rawValue: "20260714-033320-a1b2") != nil)
        #expect(QARunID(rawValue: "not-a-run-id") == nil)
        #expect(QARunID(rawValue: "20260714-033320-A1B2") == nil)
        #expect(QARunID(rawValue: "20260714-033320-a1b23") == nil)
        #expect(QARunID(rawValue: "") == nil)
    }
}

struct QAArtifactMarkerTests {
    private let runID = QARunID.generate(
        date: Date(timeIntervalSince1970: 1_784_000_000),
        suffix: "a1b2"
    )

    @Test
    func noteTagsCarryBaseAndRunTags() {
        #expect(QAArtifactMarker.noteTags(runID: runID) == [
            "wb-qa-test",
            "wb-qa-test-run-20260714-033320-a1b2"
        ])
    }

    @Test
    func markedBodyEndsWithMarkerLineAndRoundTrips() {
        let body = QAArtifactMarker.marked("Reviewed the plan.", runID: runID)

        #expect(body == "Reviewed the plan.\n\n[wb-qa-test:run:20260714-033320-a1b2]")
        #expect(QAArtifactMarker.isMarked(body))
        #expect(QAArtifactMarker.isMarked(body, runID: runID))
        #expect(QAArtifactMarker.runID(in: body) == runID)
    }

    @Test
    func unmarkedTextIsNotMatched() {
        #expect(!QAArtifactMarker.isMarked("Reviewed the plan."))
        #expect(!QAArtifactMarker.isMarked(nil))
        #expect(QAArtifactMarker.runID(in: "Reviewed the plan.") == nil)
        #expect(QAArtifactMarker.runID(in: nil) == nil)
    }

    @Test
    func markerForDifferentRunDoesNotMatchScopedCheck() {
        let other = QARunID.generate(
            date: Date(timeIntervalSince1970: 1_784_000_000),
            suffix: "z9z9"
        )
        let body = QAArtifactMarker.marked("Task detail.", runID: runID)

        #expect(QAArtifactMarker.isMarked(body))
        #expect(!QAArtifactMarker.isMarked(body, runID: other))
    }

    @Test
    func malformedRunIDInsideMarkerIsIgnored() {
        #expect(QAArtifactMarker.runID(in: "[wb-qa-test:run:hello]") == nil)
        #expect(QAArtifactMarker.isMarked("[wb-qa-test:run:hello]"))
    }

    @Test
    func testTagDetectionMatchesBaseOrRunTag() {
        #expect(QAArtifactMarker.hasTestTag(["wb-qa-test"]))
        #expect(QAArtifactMarker.hasTestTag(["wb-qa-test-run-20260713-221320-a1b2"]))
        #expect(!QAArtifactMarker.hasTestTag(["Meeting"]))
        #expect(!QAArtifactMarker.hasTestTag([]))
        #expect(!QAArtifactMarker.hasTestTag(nil))
    }

    @Test
    func tombstoneContentIsMarkedAndPreservesRunID() {
        let content = QAArtifactMarker.tombstoneContent(runID: runID)

        #expect(QAArtifactMarker.isTombstone(content))
        #expect(QAArtifactMarker.isMarked(content))
        #expect(QAArtifactMarker.runID(in: content) == runID)

        let anonymous = QAArtifactMarker.tombstoneContent(runID: nil)
        #expect(QAArtifactMarker.isTombstone(anonymous))
        #expect(QAArtifactMarker.runID(in: anonymous) == nil)
    }
}
