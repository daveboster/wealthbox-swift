import Foundation

/// The tagging convention for QA-workspace test artifacts:
///
/// - Every test-created **note** carries the `wb-qa-test` tag plus a
///   per-run tag (`wb-qa-test-run-<runID>`) — tags are a documented note
///   create/update attribute.
/// - **Tasks have no tags field** (tags are documented on Contacts and Notes
///   only), so for tasks the run id rides the `description` as a marker line,
///   which doubles as the sweep key.
/// - Notes carry the marker line in `content` as well, so the sweep works
///   even if live tag behavior drifts from the docs.
///
/// The marker line is `[wb-qa-test:run:<runID>]` on its own line at the end
/// of the body. Sweeps recognize artifacts by the marker prefix or the tags;
/// anything without a marker is structurally invisible to the sweep.
public enum QAArtifactMarker {
    /// The base tag every test-created note carries.
    public static let baseTag = "wb-qa-test"

    /// Prefix for the per-run note tag.
    public static let runTagPrefix = "wb-qa-test-run-"

    /// Marker-line prefix shared by run markers and the swept tombstone.
    public static let markerPrefix = "[wb-qa-test"

    /// The tombstone marker a swept note's content carries.
    public static let sweptMarker = "[wb-qa-test:swept]"

    /// The tags for a test-created note: `["wb-qa-test",
    /// "wb-qa-test-run-<runID>"]`.
    public static func noteTags(runID: QARunID) -> [String] {
        [baseTag, "\(runTagPrefix)\(runID.rawValue)"]
    }

    /// The marker line carrying a run id.
    public static func markerLine(runID: QARunID) -> String {
        "[wb-qa-test:run:\(runID.rawValue)]"
    }

    /// Appends the run marker line to a note body or task description.
    public static func marked(_ body: String, runID: QARunID) -> String {
        "\(body)\n\n\(markerLine(runID: runID))"
    }

    /// Whether text carries any wb-qa-test marker (run marker or
    /// tombstone).
    public static func isMarked(_ text: String?) -> Bool {
        text?.contains(markerPrefix) ?? false
    }

    /// Whether text carries the marker for a specific run.
    public static func isMarked(_ text: String?, runID: QARunID) -> Bool {
        text?.contains(markerLine(runID: runID)) ?? false
    }

    /// Extracts the first run id embedded in text, if any.
    public static func runID(in text: String?) -> QARunID? {
        guard let text else { return nil }
        guard let match = text.firstMatch(of: /\[wb-qa-test:run:(\d{8}-\d{6}-[a-z0-9]{4})\]/) else {
            return nil
        }
        return QARunID(rawValue: String(match.1))
    }

    /// Whether a tag list carries the wb-qa-test convention.
    public static func hasTestTag(_ tags: [String]?) -> Bool {
        guard let tags else { return false }
        return tags.contains { $0 == baseTag || $0.hasPrefix(runTagPrefix) }
    }

    /// The content a swept (tombstoned) note is rewritten to. Notes have no
    /// documented delete endpoint, so the sweep replaces the body while
    /// preserving the run marker for auditability.
    public static func tombstoneContent(runID: QARunID?) -> String {
        var lines = ["Swept QA test artifact.", "", sweptMarker]
        if let runID {
            lines.append(markerLine(runID: runID))
        }
        return lines.joined(separator: "\n")
    }

    /// Whether note content is already a swept tombstone.
    public static func isTombstone(_ text: String?) -> Bool {
        text?.contains(sweptMarker) ?? false
    }
}
