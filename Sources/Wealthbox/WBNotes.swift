import Foundation

/// The list envelope returned by `GET /v1/notes`.
///
/// Wealthbox returns the note collection under a `status_updates` key (not
/// `notes`) — the documented response shape for "Retrieve all notes". The
/// `notes` computed property is provided so call sites can stay readable.
///
/// Wealthbox uses a page-based pagination scheme (`page` / `per_page`) across
/// its list endpoints, returned as top-level fields alongside the collection
/// (mirroring `WBContacts` and `WBTasks`). Both are optional so a response
/// that omits them still decodes.
public struct WBNotes: WBData, Codable, Sendable {
    public var json: String?

    public let statusUpdates: [WBNote]
    public var page: Int?
    public var perPage: Int?

    /// The notes in this page of results (`status_updates` in the raw JSON).
    public var notes: [WBNote] { statusUpdates }

    public init(_ statusUpdates: [WBNote], page: Int? = nil, perPage: Int? = nil) {
        self.statusUpdates = statusUpdates
        self.page = page
        self.perPage = perPage
    }

    private enum CodingKeys: String, CodingKey {
        case statusUpdates = "status_updates"
        case perPage = "per_page"
        case page
    }

    public static func fromJSONString(_ jsonString: String) -> WBNotes {
        return DataHelpers.fromJSONString(jsonString, as: WBNotes.self)
    }

    public static func decode(_ jsonString: String) throws -> WBNotes {
        return try DataHelpers.decode(jsonString, as: WBNotes.self)
    }

    public static func sample() -> WBNotes {
        return fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        return """
        {
          "status_updates": [
        \(WBNote.sampleJSON())
          ],
          "per_page": 25,
          "page": 1
        }
        """
    }
}
